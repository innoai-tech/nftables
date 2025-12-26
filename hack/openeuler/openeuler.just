pkg arch version:
    docker buildx build \
        --build-arg VERSION={{ version }} \
        --platform linux/{{ arch }} \
        --output type=local,dest=../../target \
        .

pkg-all: (pkg "amd64" "22.03") (pkg "arm64" "22.03") (pkg "amd64" "20.03") (pkg "arm64" "20.03")
