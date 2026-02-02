import httpx
import pytest

BASE_URL = "http://localhost:8443"
TEST_INDEX = "test-index"


@pytest.fixture(autouse=True, scope="session")
def cleanup_index():
    with httpx.Client(base_url=BASE_URL, verify=False) as c:
        c.delete(f"/elastic/indices/{TEST_INDEX}")


@pytest.fixture(scope="module")
def client():
    with httpx.Client(base_url=BASE_URL, verify=False) as c:
        yield c


def test_missing_index_returns_404(client):
    resp = client.get("elastic/search/indexdne?q=hello")
    assert resp.status_code == 404


@pytest.fixture(scope="module")
def created_doc(client):
    resp = client.post(
        f"/elastic/documents/{TEST_INDEX}",
        json={"name": "hello", "message": "world"},
    )
    assert resp.status_code == 200
    data = resp.json()
    return data


def test_write_document(created_doc):
    assert created_doc["result"] == "created"
    assert "id" in created_doc
    assert created_doc["index"] == TEST_INDEX


def test_read_document(client, created_doc):
    doc_id = created_doc["id"]
    resp = client.get(f"/elastic/documents/{TEST_INDEX}/{doc_id}")
    assert resp.status_code == 200
    body = resp.json()
    assert body["name"] == "hello"
    assert body["message"] == "world"


def test_search_document(client, created_doc):
    resp = client.get(f"/elastic/search/{TEST_INDEX}", params={"q": "hello"})
    assert resp.status_code == 200
    body = resp.json()
    assert body["total"] == 1
    assert any(hit["name"] == "hello" for hit in body["hits"])
