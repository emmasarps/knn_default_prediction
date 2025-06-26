FROM rocker/tidyverse:latest

# Install additional system dependencies
RUN apt-get update && apt-get install -y \
    libgit2-dev libcurl4-openssl-dev libssl-dev libxml2-dev \
    libfontconfig1-dev libharfbuzz-dev libfribidi-dev libjpeg-dev libtiff5-dev \
    && rm -rf /var/lib/apt/lists/*

# Install extra R packages (not already in tidyverse)
RUN R -e "install.packages(c('descr', 'kknn', 'caret'), dependencies = TRUE, repos = 'https://cloud.r-project.org')"

# Optional: Install ggthemr from GitHub
RUN R -e "install.packages('devtools'); devtools::install_github('cttobin/ggthemr')"

# Copy code
WORKDIR /app
COPY R/credit_default_pro.R .

# Run the script when the container starts
CMD ["Rscript", "credit_default_pro.R"]
