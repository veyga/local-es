from contextlib import asynccontextmanager
from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
from fastapi import (
    FastAPI,
    Depends,
    HTTPException,
    status,
)
from log import LOG
from .elastic import router as elastic_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    LOG.info("🎬 Starting client service")
    yield


app = FastAPI(
    lifespan=lifespan,
)
app.include_router(elastic_router)

bearer_scheme = HTTPBearer()


# not using any sort of auth since this is just a local demo
def __verify_token(expected_token: str):
    """Create a bearer token verification dependency.

    Returns a FastAPI dependency function that validates bearer tokens
    against an expected value.

    Args:
        expected_token (str): The token value to validate against

    Returns:
        Callable: A dependency function that validates the bearer token
            and raises HTTP 401 if invalid
    """

    def inner(credentials: HTTPAuthorizationCredentials = Depends(bearer_scheme)):
        if credentials.credentials != expected_token:
            raise HTTPException(
                status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid token"
            )
        return credentials

    return inner


@app.get("/health", include_in_schema=False)
def health() -> dict:
    """Service health check endpoint."""
    return {"status": "ok"}
