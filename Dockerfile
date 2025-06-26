FROM r-base:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libgit2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libfreetype6-dev \
    libtiff5-dev \
    libjpeg-dev \
    && rm -rf /var/lib/apt/lists/*

# Install CRAN packages in a separate layer
RUN R -e "install.packages(c('devtools', 'ISLR', 'tidyverse', 'descr', 'kknn', 'caret', 'ggplot2', 'dplyr'), dependencies=TRUE, repos='http://cran.rstudio.com')"

# Install ggthemr from GitHub
RUN R -e "devtools::install_github('cttobin/ggthemr')"

# Copy only the R script
COPY R/credit_default_pro.R /credit_default_pro.R

# Run script on container startup
CMD ["Rscript", "/credit_default_pro.R"]
