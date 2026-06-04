const itemsBody = document.querySelector("#itemsBody");
const itemForm = document.querySelector("#itemForm");
const formMessage = document.querySelector("#formMessage");
const refreshBtn = document.querySelector("#refreshBtn");
const healthStatus = document.querySelector("#healthStatus");

async function request(path, options = {}) {
  const response = await fetch(path, options);
  if (!response.ok) {
    let message = `${response.status} ${response.statusText}`;
    try {
      const payload = await response.json();
      message = payload.detail || JSON.stringify(payload);
    } catch {
      // Keep default HTTP message.
    }
    throw new Error(message);
  }
  if (response.status === 204) {
    return null;
  }
  return response.json();
}

function money(value) {
  return Number(value).toLocaleString("en-US", {
    style: "currency",
    currency: "USD",
  });
}

function setMessage(text, isError = false) {
  formMessage.textContent = text;
  formMessage.style.color = isError ? "var(--danger)" : "var(--muted)";
}

async function loadHealth() {
  try {
    const health = await request("/health");
    healthStatus.className = `status-card ${health.status === "ok" ? "ok" : "error"}`;
    healthStatus.querySelector("span:last-child").textContent = `RDS ${health.rds} / S3 ${health.s3}`;
  } catch {
    healthStatus.className = "status-card error";
    healthStatus.querySelector("span:last-child").textContent = "Health error";
  }
}

async function loadItems() {
  itemsBody.innerHTML = `<tr><td colspan="5" class="empty">Loading items</td></tr>`;
  try {
    const items = await request("/items/");
    if (!items.length) {
      itemsBody.innerHTML = `<tr><td colspan="5" class="empty">No items yet</td></tr>`;
      return;
    }

    itemsBody.innerHTML = items
      .map(
        (item) => `
          <tr>
            <td>${item.id}</td>
            <td>
              <strong>${escapeHtml(item.name)}</strong>
              <div class="message">${escapeHtml(item.description || "")}</div>
            </td>
            <td>${money(item.price)}</td>
            <td>${item.file_name ? escapeHtml(item.file_name) : "No file"}</td>
            <td>
              <div class="actions">
                <div class="upload-control">
                  <input id="file-${item.id}" type="file" />
                  <button type="button" class="secondary" data-upload="${item.id}">Upload</button>
                </div>
                <button type="button" class="secondary" data-download="${item.id}">Link</button>
                <button type="button" class="danger" data-delete="${item.id}">Delete</button>
              </div>
            </td>
          </tr>
        `
      )
      .join("");
  } catch (error) {
    itemsBody.innerHTML = `<tr><td colspan="5" class="empty">${escapeHtml(error.message)}</td></tr>`;
  }
}

function escapeHtml(value) {
  return String(value).replace(/[&<>"']/g, (char) => {
    const entities = {
      "&": "&amp;",
      "<": "&lt;",
      ">": "&gt;",
      '"': "&quot;",
      "'": "&#039;",
    };
    return entities[char];
  });
}

itemForm.addEventListener("submit", async (event) => {
  event.preventDefault();
  const formData = new FormData(itemForm);
  const payload = {
    name: formData.get("name"),
    description: formData.get("description") || null,
    price: Number(formData.get("price")),
  };

  setMessage("Creating item");
  try {
    await request("/items/", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(payload),
    });
    itemForm.reset();
    setMessage("Item created");
    await loadItems();
  } catch (error) {
    setMessage(error.message, true);
  }
});

itemsBody.addEventListener("click", async (event) => {
  const uploadId = event.target.dataset.upload;
  const downloadId = event.target.dataset.download;
  const deleteId = event.target.dataset.delete;

  try {
    if (uploadId) {
      const fileInput = document.querySelector(`#file-${uploadId}`);
      if (!fileInput.files.length) {
        alert("Choose a file first.");
        return;
      }
      const body = new FormData();
      body.append("file", fileInput.files[0]);
      await request(`/items/${uploadId}/upload`, { method: "POST", body });
      await loadItems();
      return;
    }

    if (downloadId) {
      const result = await request(`/items/${downloadId}/file`);
      window.open(result.download_url, "_blank", "noopener,noreferrer");
      return;
    }

    if (deleteId) {
      if (!confirm(`Delete item ${deleteId}?`)) {
        return;
      }
      await request(`/items/${deleteId}`, { method: "DELETE" });
      await loadItems();
    }
  } catch (error) {
    alert(error.message);
  }
});

refreshBtn.addEventListener("click", () => {
  loadHealth();
  loadItems();
});

loadHealth();
loadItems();
