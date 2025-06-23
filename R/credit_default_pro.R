#setwd
# Credit Card Default Detection with KNN - R Project by Emmanuel Sarpong
# Load all required packages for data prep, modeling, and evaluation

library(ISLR)        # Contains the 'Default' dataset we'll use
library(tidyverse)   # For data manipulation and visualization
library(ggthemr)      # For plot themes
library(descr)       # For frequency tables (like CrossTable)
library(kknn)        # For performing KNN classification
library(caret)       # For confusion matrix and model evaluation
library(ggplot2)
library(dplyr)

# Clean up everything from memory to start fresh
rm(list=ls())

# Set a seed so our random results can be repeated every time
set.seed(42)

# Turn off scientific notation for large numbers (e.g., 1e+05 → 100000)
options(scipen=10000)

# Set a clean visual theme for all ggplot charts
ggthemr('flat')

# Load the Default dataset from the ISLR package
data(Default)

# Explore the structure of the dataset
dim(Default)          # Check the number of rows and columns
names(Default)        # List all the variable names
head(Default, 10)     # Preview the first 10 rows of data

# Keep only the columns needed for the model: default (target), balance and income (features)
Default <- Default %>%
  select(default, balance, income)

# View summary statistics for each column
summary(Default)
# View a frequency table of the 'default' column (how many 'Yes' vs 'No')
CrossTable(Default$default)

# Plot a histogram to see how credit card balances are distributed
ggplot(data = Default) +
  geom_histogram(aes(x = balance), bins = 30, fill = "skyblue", color = "black") +
  labs(title = "Distribution of Credit Card Balances",
       x = "Balance",
       y = "Count of People")
# Save the histogram as a PNG file
ggsave("balance_histogram.png", width = 6, height = 4, dpi = 300)

# Plot a histogram to see how incomes are distributed
ggplot(data = Default) +
  geom_histogram(aes(x = income), bins = 30, fill = "lightgreen", color = "black") +
  labs(title = "Distribution of Income",
       x = "Income",
       y = "Count of People")
#Saving of the graph
ggsave("income_histogram.png", width = 6, height = 4, dpi = 300)

# Create a boxplot of balance grouped by default status
ggplot(data = Default) +
  geom_boxplot(aes(x = default, y = balance), fill = "tomato", color = "black") +
  labs(title = "Balance by Default Status",
       x = "Default (Yes/No)",
       y = "Credit Card Balance")
ggsave("balance_boxplot.png", width = 6, height = 4, dpi = 300)

# Scatter plot of balance vs. income, colored by default status
ggplot(data = Default) +
  geom_point(aes(x = balance, y = income, color = default), alpha = 0.5) +
  labs(title = "Balance vs. Income Colored by Default Status",
       x = "Balance",
       y = "Income")
ggsave("balance_vs_income_scatter.png", width = 6, height = 4, dpi = 300)

set.seed(42)  # For reproducibility

# Randomly shuffle the rows
rows <- sample(1:nrow(Default))

# 75% for training, 25% for testing
training <- Default[rows[1:7500], ]
test <- Default[rows[7501:10000], ]

## Standardize balance and income in training set
#Preprocess predictors of the training set, i.e., center and scale them.
training <- training %>% mutate(
  balance = scale(balance),
  income = scale(income)
)
#Standardize the variables in the test set using the mean and standard deviation computed on the training set.
test <- test %>% mutate(
  balance = (balance - attr(training$balance, "scaled:center")) / attr(training$balance, "scaled:scale"),
  income = (income - attr(training$income, "scaled:center")) / attr(training$income, "scaled:scale")
)

## Train classifier
# Train KNN model with k = 7
knn7 <- kknn(default ~ ., train = training, test = test, k = 7)

# Preview predictions for k = 7
head(knn7$fitted.values)  # Predicted labels (Yes/No)
head(knn7$prob)           # Predicted probabilities


# Train KNN model with k = 9
knn9 <- kknn(default ~ ., train = training, test = test, k = 9)

# Preview predictions for k = 9
head(knn9$fitted.values)  # Predicted labels (Yes/No)
head(knn9$prob)           # Predicted probabilities

# Define a threshold for deciding between "Yes" and "No" for k = 7
decision_threshold <- 0.5

# Combine test data with predicted probabilities from k = 7
test_k7 <- test %>%
  mutate(
    prob_default = knn7$prob[, "Yes"],  # probability of default
    pred_label = as.factor(ifelse(prob_default > decision_threshold, "Yes", "No"))
  )

head(test_k7, 10)

#ConfusionMatrix
confusionMatrix(
  data = test_k7$pred_label,         # what the model predicted
  reference = test_k7$default,       # what really happened
  positive = "Yes",                  # treat "Yes" as the positive class
  mode = "prec_recall"               # show precision & recall, not just accuracy
)
#threshold for decison for k = 9
decision_threshold <- 0.5
test_k9 <- test %>%
  mutate(
    prob_default = knn9$prob[, "Yes"],  # probability of default
    pred_label = as.factor(ifelse(prob_default > decision_threshold, "Yes", "No"))
  )
head(test_k9, 10)
#ConfusionMatrix 
confusionMatrix(test_k9$pred_label, reference = test_k9$default, 
                positive = "Yes", mode = "prec_recall")

##Generating a grid of fake customers (simulated data)
# Generate simulated customer grid
sim <- expand.grid(
  balance = seq(min(training$balance) - 1, max(training$balance) + 1, by = 0.1),
  income  = seq(min(training$income) - 1,  max(training$income) + 1,  by = 0.1)
)

# Predict with KNN (k = 7)
knn_model <- kknn(default ~ ., train = training, test = sim, k = 7)
sim_preds <- knn_model$fitted.values

# Prepare decision boundary data
sim_w_preds <- bind_rows(
  mutate(sim, label = "Yes", prob_cls = ifelse(sim_preds == "Yes", 1, 0)),
  mutate(sim, label = "No",  prob_cls = ifelse(sim_preds == "No",  1, 0))
)
# Add predictions to the sim dataset
sim$pred_label <- sim_preds

##Plot training data + predicted regions + decision boundary
ggplot() +
  # Plot actual training data as larger, semi-transparent points
  geom_point(data = training,
             aes(x = balance, y = income, color = default),
             size = 3, alpha = 0.5) +
  
  # Plot prediction zones from the simulation (tiny points)
  geom_point(data = sim,
             aes(x = balance, y = income, color = pred_label),
             size = 0.5) +
  
  # Draw the decision boundary (contour where the model flips decision)
  geom_contour(data = sim_w_preds,
               aes(x = balance, y = income, z = prob_cls, group = label, color = label),
               bins = 1, linewidth = 1) +
  
  labs(
    title = "KNN Decision Boundary (k = 7)",
    x = "Balance (Standardized)",
    y = "Income (Standardized)",
    color = "Default Status"
  )
                
ggsave("knn_decision_boundary_k7.png", width = 8, height = 6, dpi = 300)

                       