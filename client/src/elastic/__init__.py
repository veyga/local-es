import elasticsearch
from log import LOG
from fastapi import APIRouter, HTTPException
from fastapi import (
    Body,
    Path,
    Query,
)
from .util import get_client

RELATIVE_PATH = "/elastic"

METADATA = [
    {
        "name": RELATIVE_PATH,
        "description": "endpoint for elastic testing",
    },
]
router = APIRouter(prefix=RELATIVE_PATH, tags=[RELATIVE_PATH])


@router.post("/documents/{index}")
def write_document(
    index: str = Path(..., description="Elasticsearch index name"),
    document: dict = Body(..., description="Document to index"),
):
    es = get_client()
    # forces ES to refresh the shard immediately after indexing, so the document is searchable right away.
    result = es.index(index=index, document=document, refresh=True)
    return {"result": result["result"], "id": result["_id"], "index": result["_index"]}


@router.get("/documents/{index}/{doc_id}")
def read_document(
    index: str = Path(..., description="Elasticsearch index name"),
    doc_id: str = Path(..., description="Document ID"),
):
    es = get_client()
    try:
        result = es.get(index=index, id=doc_id)
        return result["_source"]
    except Exception as e:
        raise HTTPException(status_code=404, detail=str(e))


@router.delete("/indices/{index}")
def delete_index(
    index: str = Path(..., description="Elasticsearch index name"),
):
    es = get_client()
    try:
        result = es.indices.delete(index=index)
        return result
    except elasticsearch.NotFoundError:
        raise HTTPException(status_code=404, detail=f"Index '{index}' not found")


@router.get("/search/{index}")
def search_documents(
    index: str = Path(..., description="Elasticsearch index name"),
    q: str = Query(..., description="Search query string"),
):
    try:
        es = get_client()
        result = es.search(
            index=index,
            query={"multi_match": {"query": q, "fields": ["*"]}},
        )
        return {
            "total": result["hits"]["total"]["value"],
            "hits": [hit["_source"] for hit in result["hits"]["hits"]],
        }
    except Exception as e:
        LOG.error(e)
        match e:
            case elasticsearch.NotFoundError():
                raise HTTPException(status_code=404, detail=str(e))
        return {
            "total": 0,
            "hits": [],
        }
