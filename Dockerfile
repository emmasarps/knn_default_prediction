FROM r-base:latest

# Install system dependencies for R packages and devtools
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

# Install devtools to install ggthemr from GitHub
RUN R -e "install.packages('devtools', dependencies=TRUE, repos='http://cran.rstudio.com')"

# Install ggthemr from GitHub
RUN R -e "devtools::install_github('cttobin/ggthemr')"

# Install all required CRAN packages
RUN R -e "install.packages(c('ISLR', 'tidyverse', 'descr', 'kknn', 'caret', 'ggplot2', 'dplyr'), dependencies=TRUE, repos='http://cran.rstudio.com')"

# Copy your R script into the container
COPY R/credit_default_pro.R /credit_default_pro.R

# Run the R script when container starts
CMD ["Rscript", "/credit_default_pro.R"]
