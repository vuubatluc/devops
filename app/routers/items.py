from typing import List
import uuid

from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy.orm import Session

from app.database import get_db
from app.models.item import ItemCreate, ItemDB, ItemResponse
from app.s3 import delete_file, get_presigned_url, upload_file


router = APIRouter(prefix="/items", tags=["Items"])


@router.get("/", response_model=List[ItemResponse])
def list_items(db: Session = Depends(get_db)):
    return db.query(ItemDB).order_by(ItemDB.id.desc()).all()


@router.post("/", response_model=ItemResponse, status_code=201)
def create_item(item: ItemCreate, db: Session = Depends(get_db)):
    db_item = ItemDB(**item.model_dump())
    db.add(db_item)
    db.commit()
    db.refresh(db_item)
    return db_item


@router.post("/{item_id}/upload", response_model=ItemResponse)
async def upload_item_file(
    item_id: int,
    file: UploadFile = File(...),
    db: Session = Depends(get_db),
):
    item = db.query(ItemDB).filter(ItemDB.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    if item.s3_key:
        delete_file(item.s3_key)

    file_content = await file.read()
    s3_key = f"items/{item_id}/{uuid.uuid4().hex}_{file.filename}"
    upload_file(file_content, s3_key, file.content_type)

    item.s3_key = s3_key
    item.file_name = file.filename
    item.file_url = f"s3://{s3_key}"
    db.commit()
    db.refresh(item)
    return item


@router.get("/{item_id}/file")
def get_file_url(item_id: int, db: Session = Depends(get_db)):
    item = db.query(ItemDB).filter(ItemDB.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")
    if not item.s3_key:
        raise HTTPException(status_code=404, detail="No file uploaded for this item")

    return {"download_url": get_presigned_url(item.s3_key), "expires_in": "1 hour"}


@router.delete("/{item_id}", status_code=204)
def delete_item(item_id: int, db: Session = Depends(get_db)):
    item = db.query(ItemDB).filter(ItemDB.id == item_id).first()
    if not item:
        raise HTTPException(status_code=404, detail="Item not found")

    if item.s3_key:
        delete_file(item.s3_key)

    db.delete(item)
    db.commit()
