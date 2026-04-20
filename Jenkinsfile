pipeline {
    agent { label 'wsl && docker' }

    environment {
        REGISTRY = 'docker.xcl.turboyan.com:24443'
        IMAGE = 'docker.xcl.turboyan.com:24443/project/thub-dev-ubuntu22'
        CONTAINER_LANG = 'C.UTF-8'
        ROOT_PASSWORD = 'root'
        HOST_HOME = '/home/turboyan'
    }

    stages {
        stage('Docker Login') {
            steps {
                sh '''
                echo "docker-pw" | docker login $REGISTRY -u docker --password-stdin
                '''
            }
        }

        stage('Pull Image') {
            steps {
                sh '''
                docker pull $IMAGE
                '''
            }
        }

        stage('Prepare Host Dirs') {
            steps {
                sh '''
                mkdir -p "$HOST_HOME/.cache" "$HOST_HOME/.ccache"
                # .ssh 必须存在且权限正确，否则 ssh/git 会拒绝使用
                if [ ! -d "$HOST_HOME/.ssh" ]; then
                    echo "ERROR: $HOST_HOME/.ssh not found on host"; exit 1
                fi
                '''
            }
        }

        stage('Build In Docker') {
            steps {
                sh '''
                docker run --rm \
                  -e LANG="$CONTAINER_LANG" \
                  -e LANGUAGE="$CONTAINER_LANG" \
                  -e LC_ALL="$CONTAINER_LANG" \
                  -e ROOT_PASSWORD="$ROOT_PASSWORD" \
                  -e HOME=/root \
                  -e CCACHE_DIR=/root/.ccache \
                  -v "$WORKSPACE":/root/workspace \
                  -v "$HOST_HOME/.cache":/root/.cache \
                  -v "$HOST_HOME/.ccache":/root/.ccache \
                  -v "$HOST_HOME/.ssh":/root/.ssh:ro \
                  -w /root/workspace \
                  $IMAGE \
                  bash -lc '
                    set -ex
                    echo "== prepare python link =="
                    ln -sf /usr/bin/python2 /usr/bin/python

                    echo "== fix ssh permissions (read-only mount, copy if needed) =="
                    # 容器内 root 使用 /root/.ssh，确保 known_hosts 包含 git 服务器
                    chmod 700 /root/.ssh 2>/dev/null || true
                    find /root/.ssh -type f -exec chmod 600 {} \\; 2>/dev/null || true

                    echo "== build uboot =="
                    ./build.sh -m uboot -n
                    echo "== build kernel =="
                    ./build.sh -m kernel -n
                    echo "== build lirc =="
                    ./build.sh -m lirc -n
                    echo "== build evtest =="
                    ./build.sh -m evtest -n
                    echo "== build app =="
                    ./build.sh -m app -n
                    echo "== build pack =="
                    ./build.sh -m pack -n
                  '
                '''
            }
        }
    }
}