pipeline {
    agent { label 'wsl && docker' }

    environment {
        REGISTRY         = 'docker.xcl.turboyan.com:24443'
        IMAGE            = 'docker.xcl.turboyan.com:24443/project/thub-dev-ubuntu22'
        CONTAINER_LANG   = 'C.UTF-8'
        ROOT_PASSWORD    = 'root'
        HOST_HOME        = '/home/turboyan'
        // 强制 Python/Glibc 行缓冲，避免子进程把 stdout 攒在内存里
        PYTHONUNBUFFERED = '1'
    }

    options {
        // 控制台实时刷新 + 颜色
        ansiColor('xterm')
        timestamps()
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

        stage('Build In Docker') {
            steps {
                // 外层 tee：同时写到 Jenkins 控制台和 build.log
                sh '''
                set -o pipefail
                mkdir -p "$WORKSPACE/logs"

                docker run --rm -t \
                  -e LANG="$CONTAINER_LANG" \
                  -e LANGUAGE="$CONTAINER_LANG" \
                  -e LC_ALL="$CONTAINER_LANG" \
                  -e ROOT_PASSWORD="$ROOT_PASSWORD" \
                  -e HOME=/root \
                  -e CCACHE_DIR=/root/.ccache \
                  -e PYTHONUNBUFFERED=1 \
                  -e TERM=xterm-256color \
                  -v "$WORKSPACE":/root/workspace \
                  -v "$HOST_HOME/.cache":/root/.cache \
                  -v "$HOST_HOME/.ccache":/root/.ccache \
                  -v "$HOST_HOME/.ssh":/root/.ssh:ro \
                  -w /root/workspace \
                  "$IMAGE" \
                  bash -lc '
                    set -e
                    # 用 script 包一层：给所有子进程再分配一个 PTY，
                    # 这样即便工具内部用 isatty() 判断也会走行缓冲分支
                    script -q -e -c "
                      set -ex
                      echo \\"== prepare python link ==\\"
                      ln -sf /usr/bin/python2 /usr/bin/python

                      echo \\"== fix ssh permissions ==\\"
                      chmod 700 /root/.ssh 2>/dev/null || true
                      find /root/.ssh -type f -exec chmod 600 {} \\; 2>/dev/null || true

                      echo \\"== build uboot ==\\"  ; ./build.sh -m uboot  -n
                      echo \\"== build kernel ==\\" ; ./build.sh -m kernel -n
                      echo \\"== build lirc ==\\"   ; ./build.sh -m lirc   -n
                      echo \\"== build evtest ==\\" ; ./build.sh -m evtest -n
                      echo \\"== build app ==\\"    ; ./build.sh -m app    -n
                      echo \\"== build pack ==\\"   ; ./build.sh -m pack   -n
                    " /dev/null
                  ' 2>&1 | tee "$WORKSPACE/logs/build.log"
                '''
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'logs/build.log', allowEmptyArchive: true
        }
    }
}