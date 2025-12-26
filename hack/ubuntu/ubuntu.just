pkg arch version:
    docker buildx build \
        --build-arg VERSION={{ version }} \
        --platform linux/{{ arch }} \
        --output type=local,dest=../../target \
        .

pkg-all: (pkg "amd64" "20.04") (pkg "arm64" "20.04") (pkg "amd64" "18.04") (pkg "arm64" "18.04")
