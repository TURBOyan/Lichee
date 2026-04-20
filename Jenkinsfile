pipeline {
    agent { label 'wsl && docker' }

    options {
        timestamps()
        // ansiColor('xterm')   // 需要安装 AnsiColor Plugin，没装就先注释掉
    }

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
                sh 'echo "docker-pw" | docker login $REGISTRY -u docker --password-stdin'
            }
        }

        stage('Pull Image') {
            steps {
                sh 'docker pull $IMAGE'
            }
        }

        stage('Prepare Host Dirs') {
            steps {
                sh '''
                mkdir -p "$HOST_HOME/.cache" "$HOST_HOME/.ccache"
                '''
            }
        }

        stage('Build In Docker') {
            steps {
                // -t 分配 PTY，让子进程行缓冲；tee 双写到 build.log
                sh '''
                set -o pipefail
                docker run --rm -t \
                  -e LANG="$CONTAINER_LANG" \
                  -e LANGUAGE="$CONTAINER_LANG" \
                  -e LC_ALL="$CONTAINER_LANG" \
                  -e ROOT_PASSWORD="$ROOT_PASSWORD" \
                  -e HOME=/root \
                  -e CCACHE_DIR=/root/.ccache \
                  -e PYTHONUNBUFFERED=1 \
                  -v "$WORKSPACE":/root/workspace \
                  -v "$HOST_HOME/.cache":/root/.cache \
                  -v "$HOST_HOME/.ccache":/root/.ccache \
                  -v "$HOST_HOME/.ssh":/root/.ssh:ro \
                  -w /root/workspace \
                  $IMAGE \
                  stdbuf -oL -eL bash -lc '
                    set -ex
                    echo "== prepare python link =="
                    ln -sf /usr/bin/python2 /usr/bin/python

                    echo "== build uboot ==";  ./build.sh -m uboot
                    echo "== build kernel =="; ./build.sh -m kernel
                    echo "== build lirc ==";   ./build.sh -m lirc
                    echo "== build evtest =="; ./build.sh -m evtest
                    echo "== build app ==";    ./build.sh -m app
                    echo "== build pack ==";   ./build.sh -m pack
                  ' 2>&1 | tee build.log
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'build.log', allowEmptyArchive: true
        }
    }
}