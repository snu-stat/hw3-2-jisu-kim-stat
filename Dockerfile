# 1. 기반 이미지 설정
FROM rocker/tidyverse:4.4.0

# 2. 시스템 의존성 설치 (ImageMagick 포함)
RUN apt-get update && apt-get install -y \
    wget \
    git \
    imagemagick \
    libmagick++-dev \
    libzmq3-dev \
    && rm -rf /var/lib/apt/lists/*

# 3. Miniconda 설치
ENV CONDA_DIR=/opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p /opt/conda && \
    rm ~/miniconda.sh

# 4. Conda 경로 설정 및 환경 생성
ENV PATH=/opt/conda/bin:$PATH
RUN /opt/conda/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/main && \
    /opt/conda/bin/conda tos accept --override-channels --channel https://repo.anaconda.com/pkgs/r && \
    /opt/conda/bin/conda create -n r-reticulate python=3.11 -y && \
    /opt/conda/envs/r-reticulate/bin/pip install numpy pandas matplotlib statsmodels jupyter


# 5. R 패키지 설치 (reticulate 및 필수 패키지)
ENV PATH=/opt/conda/envs/r-reticulate/bin:$PATH
RUN R -e "install.packages(c('reticulate', 'remotes', 'IRkernel', 'tidyverse', 'NHANES', 'Lahman', 'MASS'))" && \
    R -e "IRkernel::installspec(user = FALSE)"

# 6. reticulate가 사용할 Python 경로 고정 (환경 변수)
ENV RETICULATE_PYTHON=/opt/conda/envs/r-reticulate/bin/python

# 7. (선택) Binder 사용자를 위한 권한 설정
# Binder는 보통 'jovyan' 유저 권한으로 실행
RUN chown -R ${NB_USER:-root} /opt/conda

# 기본 실행 경로 설정
WORKDIR /home/rstudio

# 생성된 노트북과 소스 파일 복사
COPY . /home/rstudio/

ENV HOME=/home/rstudio

RUN chmod -R a+rwx /home/rstudio

# label 추가
LABEL org.opencontainers.image.source="https://github.com/snu-stat/hw3-2-jisu-kim-stat"

EXPOSE 8888

CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root", "--NotebookApp.token=", "--NotebookApp.password="]