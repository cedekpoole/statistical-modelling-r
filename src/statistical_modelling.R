# Statistical Modelling in R: Wine Quality and Hip Fracture Risk
#
# Run from the project root after placing the expected datasets in data/.
# This script covers exploratory analysis, model selection, diagnostics and evaluation.

library(corrplot)
library(RColorBrewer)
library(ggplot2)
library(ggfortify)
library(car)

# Red wine quality modelling
wine <- read.csv("data/redwine.csv")

str(wine)
summary(wine)
head(wine)
colSums(is.na(wine))


par(mfrow=c(1,1))

# Red wine exploratory analysis
ggplot(wine, aes(x=quality)) +
  geom_histogram(bins=10, fill="deepskyblue4", color="white") +
  theme_minimal()  +
  labs(x = "Quality Score",
       y = "Count")
  

cor_matrix <- cor(wine)

col_palette <- brewer.pal(n = 8, name = "RdBu")

corrplot(cor_matrix, 
         method = "color",       
         order = "original",
         type = "lower",
         col = col_palette,       
         addCoef.col = "black",   
         tl.col = "black",        
         number.cex = 0.7,
         diag = FALSE
)

# Red wine model selection and refinement
model_full <- lm(quality ~ ., data=wine)
summary(model_full)

model_stepwise <- step(model_full, direction="backward")
summary(model_stepwise)

model_refined <- update(model_stepwise, . ~ . - citric)
summary(model_refined)

model_final <- update(model_refined, . ~ . - freeSO2)

summary(model_final)

# model comparison: checking the AIC
round(AIC(model_full), 2)
round(AIC(model_stepwise), 2)
round(AIC(model_final), 2)

# Red wine diagnostics and prediction error
par(mfrow=c(2,2))

autoplot(model_final,
         which = 1:4, 
         ncol = 2,
         colour = "deepskyblue4",
         alpha = 0.4,           
         smooth.colour = "#E74C3C", 
         smooth.se = FALSE) +    
  theme_minimal()+
  theme(plot.margin = margin(t = 20, r = 10, b = 20, l = 10))


par(mfrow=c(1,1))

# check multicollinearity using VIF (Variance Inflation Factor)
vif(model_final)

# RMSE (prediction error - the amount the model deviates from the actual value)
rmse <- sigma(model_final)
round(rmse, 4)


# prediction example
predict(model_final, newdata=data.frame(volacid=0.5, chlorides=0.07,
                                        totalSO2=40, pH=3.7, sulphates=0.6,
                                        alcohol=12), interval="prediction")

# Hip fracture risk modelling
bmd_data <- read.csv("data/bmd-1.csv")

# Hip fracture exploratory analysis
str(bmd_data)
summary(bmd_data)
head(bmd_data)
colSums(is.na(bmd_data))

counts <- table(bmd_data$fracture)
print(counts)

# data preparation
bmd_data$fracture <- as.factor(bmd_data$fracture)
bmd_data$sex <- as.factor(bmd_data$sex)
bmd_data$medication <- as.factor(bmd_data$medication)


ggplot(bmd_data, aes(x = bmd, fill = fracture)) +
  geom_density(alpha = 0.6, color = NA) +      
  scale_fill_manual(values = c("deepskyblue4", "tomato"), 
                    name = "Fracture Status:",
                    labels = c("No Fracture", "Fracture")) +
  theme_minimal() +
  labs(x = "BMD", y = "Density") +
  theme(legend.position = "top")

t.test(bmd ~ fracture, data = bmd_data)

model_simple <- glm(fracture ~ bmd, data=bmd_data, family="binomial")
summary(model_simple)


# Hip fracture logistic regression
model_full <- glm(fracture ~ age + sex + weight_kg + height_cm 
                  + waiting_time + medication + bmd, 
                  data=bmd_data, family="binomial")

summary(model_full)

model_best <- step(model_full, direction="backward")
summary(model_best)

# test removal of medication
model_test <- update(model_best, . ~ . - medication)
summary(model_test)

# Hip fracture classification evaluation
probabilities <- predict(model_best, type="response")
predicted_class <- ifelse(probabilities > 0.5, 1, 0)

conf_matrix <- table(Predicted = predicted_class, 
                     Actual = bmd_data$fracture)
conf_matrix
cm_df <- as.data.frame(conf_matrix)

cm_df$Predicted <- factor(cm_df$Predicted, 
                          labels = c("No Fracture", "Fracture"))
cm_df$Actual <- factor(cm_df$Actual, 
                       labels = c("No Fracture", "Fracture"))


# confusion matrix
ggplot(cm_df, aes(x = Actual, y = Predicted, fill = Freq)) +
  geom_tile(color = "white") + 
  geom_text(aes(label = Freq), size = 8, 
            fontface = "bold", color = "white") +
  scale_fill_gradient(low = "darkgrey", high = "deepskyblue4") +
  theme_minimal() +
  labs(x = "Actual Condition", y = "Predicted Condition") +
  theme(legend.position = "none",
        axis.text = element_text(size = 12))

# work out model accuracy, sensitivity and specificity
true_neg <- conf_matrix[1,1]
true_pos <- conf_matrix[2,2]
false_pos<- conf_matrix[2,1]
false_neg <- conf_matrix[1,2]

acc <- (true_pos + true_neg) / sum(conf_matrix)
acc

sensitivity <- true_pos / (true_pos + false_neg)
sensitivity

specificity <- true_neg / (true_neg + false_pos)
specificity

# prediction Example
predict(model_best, newdata=data.frame(height_cm=170, bmd=0.64, 
                                       medication="0"), type="response")

        
