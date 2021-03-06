# Remove all objects from the current workspace.
rm(list=ls())
#Add desired packages
require(lme4)
require(nlme)
require(splines)
require(magrittr)

# Define the sequence of years in our dataset
# CROP PARAMETER.
# These are potato specific years
year = seq(from = 1981, to = 2016);
# Define the subsequence of years from year over which we make predictions in our dataset
pred.year = seq(from=23, to=36)


# Define the RMSE of two vectors
RMSE = function(m, o){
sqrt(mean((m - o)^2))
}

# There are numberYears years from 2003 to lastTestingYear
firstTestingYear <- 2003
lastTestingYear <- year[length(year)]
numberYears <- lastTestingYear - firstTestingYear + 1



# Once the yield predictions are made and stored into a csv entitled yield_prediction_csv,
# calculate the RMSEs for these yield predictions and store them into the file rmse_csv
calculateRMSE = function(yield_prediction_csv,rmse_csv)
{

    results <- read.csv(yield_prediction_csv)

    # In the  columns that belong to the dataframe read from yield_prediction_csv, the yield predictions of the first model are stored at column index 8
    # Recall that what r refers to as index 8, python refers to as index 7
    firstModelIndex <- 8


    # Get the names of the various models whose yield predictions are stored in yield_prediction_csv
    model_names <- colnames(results[firstModelIndex:length(colnames(results))])
    # The yield predictions of the final model are stored at column index lastModelIndex
    lastModelIndex <- firstModelIndex + length(model_names) - 1




    # Make the matrix that stores the RMSE, for each testing year for each model
    model_rmse_mat <- matrix(, nrow = numberYears, ncol = length(model_names))


    for (year_idx in 1:numberYears){
        # Get the test year
        test.year = year[pred.year[year_idx]]


        # In the columns that belong to the dataframe read from yield_prediction_csv, the years belonging to each entry are stored in yearIndex
        yearIndex <- 2
        # Get the portion of yield_prediction_csv whose years belong to data.test
        data.test = results[which(results[, yearIndex] %in% test.year),]

        for (j in firstModelIndex:lastModelIndex)
        {
            indexInModelNames <- j - firstModelIndex + 1
            # Get the name of the model for which we will now calculate the RMSE, using the model's data from year test.year
            model_string <- (model_names[indexInModelNames])
            # Refine data.test to consist only of those entries that have non-NA values for both the attribute "yield" and attribute model_string
            # (which is really the predicted yield) # for the particular model

            data.test.copy = data.test[!is.na(data.test[,model_string]),]
            data.test.copy = data.test.copy[!is.na(data.test.copy[,"yield"]),]
            # Calculate the RMSE
            model_rmse_mat[year_idx, indexInModelNames] <- RMSE(data.test.copy$"yield", data.test.copy[,model_string])
        }
    }

    # Save this matrix as a dataframe
    df <- data.frame(model_rmse_mat)
    # Replaces its column names by the model_names, save it, and then print some statistics
    colnames(df) <- model_names
    write.csv(df, rmse_csv)
    print("The RMSE data for all models:")
    print(df)
    print("The median RMSE data for all models:")
    print(apply(df,2,median))
    print("The mean RMSE data for all models:")
    print(apply(df,2,mean))
}



# Scale Numeric Data
# param crop_data: A data frame with numeric columns.
scaleData = function(crop_data)
{

    # Get a boolean vector such that each index in the boolean vector represents
    # whether the corrresponding column index in crop_data is numeric (TRUE) or not (FALSE)
    ind <- sapply(crop_data, is.numeric)
    # Set those column indices to FALSE that we don't want to scale.
    ind["year"] <- FALSE
    ind["State"] <- FALSE
    ind["FIPS"] <- FALSE
    ind["yield"] <- FALSE
    # Scale the indices that are, firstly, numeric and, secondly, those that we want to scale.
    crop_data[ind] <- scale(crop_data[ind])
    return(crop_data)
}



initialize = function(inputDataFile, outputYieldFile, outputStatsFile)
{

    crop_data <- inputDataFile

    # Uncomment this if you want to scale the numeric columns of your data
    # crop_data <- scaleData(crop_data)



    # Configure certain columns to be stored as categorical variables
    crop_data$FIPS = as.factor(crop_data$FIPS)
    crop_data$State = as.factor(crop_data$State)


    # Give names to the CSVs in which we will, firstly, store the results of predictions and, secondly, in which we will store the RMSEs that we calculate for these
    # predictions.

    yield_prediction_csv_1 <- outputYieldFile
    rmse_csv_1 <- outputStatsFile

    #yield_prediction_csv_1 <- "./yan_combinations_tomato.csv"
    #rmse_csv_1 <- "./yan_combinations_tomato_rmse.csv"

    # Specify the model formulas that we wish to test
    model_formulas_1 <- c(
                          "yield_ana ~ vpdave5 +  vpdave6 +  vpdave7 +  vpdave8 + precip5 +  precip6 +  precip7 +  precip8 + FIPS",
                          "yield_ana ~ vpdave5 +  vpdave6 +  vpdave7 +  vpdave8 + precip5 +  precip6 +  precip7 +  precip8 + I(precip5^2) + I(precip6^2) + I(precip7^2) + I(precip8^2) + FIPS",
                          "yield_ana ~ vpdave5 +  vpdave6 +  vpdave7 +  vpdave8 + I(vpdave5^2) + I(vpdave6^2) + I(vpdave7^2) + I(vpdave8^2) + precip5 +  precip6 +  precip7 +  precip8 + FIPS",
                          "yield_ana ~ vpdave5 +  vpdave6 +  vpdave7 +  vpdave8 + I(vpdave5^2) + I(vpdave6^2) + I(vpdave7^2) + I(vpdave8^2) + precip5 +  precip6 +  precip7 +  precip8 + I(precip5^2) + I(precip6^2) + I(precip7^2) + I(precip8^2) + FIPS",
                          "yield_ana ~ tave5 +  tave6 +  tave7 +  tave8 + precip5 +  precip6 +  precip7 +  precip8 + FIPS",
                          "yield_ana ~ tave5 +  tave6 +  tave7 +  tave8 + precip5 +  precip6 +  precip7 +  precip8 + I(precip5^2) + I(precip6^2) + I(precip7^2) + I(precip8^2) + FIPS",
                          "yield_ana ~ tave5 +  tave6 +  tave7 +  tave8 + I(tave5^2) + I(tave6^2) + I(tave7^2) + I(tave8^2) + precip5 +  precip6 +  precip7 +  precip8 + FIPS",
                          "yield_ana ~ tave5 +  tave6 +  tave7 +  tave8 + I(tave5^2) + I(tave6^2) + I(tave7^2) + I(tave8^2) + precip5 +  precip6 +  precip7 +  precip8 + I(precip5^2) + I(precip6^2) + I(precip7^2) + I(precip8^2) + FIPS",
                          "yield_ana ~ tave5 +  tave6 +  tave7 +  tave8 + precip5 +  precip6 +  precip7 +  precip8 + vpdave5 +  vpdave6 +  vpdave7 +  vpdave8 + FIPS",
                          "yield_ana ~ tave5 +  tave6 +  tave7 +  tave8 + precip5 +  precip6 +  precip7 +  precip8 + I(precip5^2) + I(precip6^2) + I(precip7^2) + I(precip8^2) + vpdave5 +  vpdave6 +  vpdave7 +  vpdave8 + FIPS",
                          "yield_ana ~ tave5 +  tave6 +  tave7 +  tave8 + I(tave5^2) + I(tave6^2) + I(tave7^2) + I(tave8^2) + precip5 +  precip6 +  precip7 +  precip8 + vpdave5 +  vpdave6 +  vpdave7 +  vpdave8 + FIPS",
                          "yield_ana ~ tave5 +  tave6 +  tave7 +  tave8 + I(tave5^2) + I(tave6^2) + I(tave7^2) + I(tave8^2) + precip5 +  precip6 +  precip7 +  precip8 + I(precip5^2) + I(precip6^2) + I(precip7^2) + I(precip8^2) + vpdave5 +  vpdave6 +  vpdave7 +  vpdave8 + FIPS",
                          "yield_ana ~ tave5 +  tave6 +  tave7 +  tave8 + precip5 +  precip6 +  precip7 +  precip8 + vpdave5 +  vpdave6 +  vpdave7 +  vpdave8 + I(vpdave5^2) + I(vpdave6^2) + I(vpdave7^2) + I(vpdave8^2) + FIPS",
                          "yield_ana ~ tave5 +  tave6 +  tave7 +  tave8 + precip5 +  precip6 +  precip7 +  precip8 + I(precip5^2) + I(precip6^2) + I(precip7^2) + I(precip8^2) + vpdave5 +  vpdave6 +  vpdave7 +  vpdave8 + I(vpdave5^2) + I(vpdave6^2) + I(vpdave7^2) + I(vpdave8^2) + FIPS",
                          "yield_ana ~ tave5 +  tave6 +  tave7 +  tave8 + I(tave5^2) + I(tave6^2) + I(tave7^2) + I(tave8^2) + precip5 +  precip6 +  precip7 +  precip8 + vpdave5 +  vpdave6 +  vpdave7 +  vpdave8 + I(vpdave5^2) + I(vpdave6^2) + I(vpdave7^2) + I(vpdave8^2) + FIPS",
                          "yield_ana ~ tave5 +  tave6 +  tave7 +  tave8 + I(tave5^2) + I(tave6^2) + I(tave7^2) + I(tave8^2) + precip5 +  precip6 +  precip7 +  precip8 + I(precip5^2) + I(precip6^2) + I(precip7^2) + I(precip8^2) + vpdave5 +  vpdave6 +  vpdave7 +  vpdave8 + I(vpdave5^2) + I(vpdave6^2) + I(vpdave7^2) + I(vpdave8^2)")


    # For each of the model formulas that we specified above, give each model configuration a name
    model_names_1 <- c('A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P')

    # For each of the model formulas, determine whether we will fit the model using lm or using lmer
    # Note that lm is the ordinary OLS function and lmer the hierarchical model function
    fitting_functions_1 <- c("lm","lm","lm","lm","lm","lm","lm","lm","lm","lm","lm","lm","lm","lm","lm","lm")

    # For each of the model formulas, specify whether the model formula uses FIPS or not, and then evi and then lst
    uses_FIPS_1 <- c("Y","Y","Y","Y","Y","Y","Y","Y","Y","Y","Y","Y","Y","Y","Y","Y")
    uses_evi_1 <- c("N","N","N","N","N","N","N","N","N","N","N","N","N","N","N","N")
    uses_lstmax_1 <- c("N","N","N","N","N","N","N","N","N","N","N","N","N","N","N","N")


    # Each of the following list suffixed variables is a list that stores as many variables as model experiments that we want to run
    # By model experiment, I refer to the collection of model configurations that one wants to test in one run of this code.
    # For example, we may wish to test model configurations using precip in one run and then model configurations using tave in another run
    # The model configurations, within the model experiment, using precip may be (for example) yield ~ precip5 + precip6 + precip7 + FIPS or yield ~ precip6 + precip7 + precip8 + FIPS

    yield_prediction_csv_list <- list(yield_prediction_csv_1)
    rmse_csv_list <- list(rmse_csv_1)
    model_formulas_list <- list(model_formulas_1)
    model_names_list <- list(model_names_1)
    fitting_functions_list <- list(fitting_functions_1)
    uses_evi_list <- list(uses_evi_1)
    uses_lstmax_list <- list(uses_lstmax_1)
    uses_FIPS_list <- list(uses_FIPS_1)



    # The number of model configurations that we wish to test
    number_models <- length(yield_prediction_csv_list)


    for (model_index in (1:number_models))
    {
        # Extract the particular variables from the list objects previously named that we wish to work with
        yield_prediction_csv <- yield_prediction_csv_list[[model_index]]
        rmse_csv <- rmse_csv_list[[model_index]]
        model_formulas <- model_formulas_list[[model_index]]
        model_names <- model_names_list[[model_index]]
        fitting_functions <- fitting_functions_list[[model_index]]
        uses_evi <- uses_evi_list[[model_index]]
        uses_lstmax <- uses_lstmax_list[[model_index]]
        uses_FIPS <- uses_FIPS_list[[model_index]]

        predictions <- vector("list", length(model_formulas))

        # If the number of model_formulas is not equal to the numer of model_names, then we forgot to specify a name for a model configuration or a
        # model configuration for some model name
        if (length(model_formulas) != length(model_names))
        {
            stop("The length of model_formulas != length of model_names")
        }

        for (formula_idx in 1:length(model_formulas))
        {
            # Get the start time for a particular model_formula
            startTime <- Sys.time()
            print(sprintf("We are running this model: %s", model_names[formula_idx]))
            # These are potato specific years
            for (year_idx in 1:numberYears){

                print(sprintf("Performing LOO by excluding year %d", (year_idx + firstTestingYear)))
                test.year = year[pred.year[year_idx]]

                #data.train is the data frame containing the data with which we can possibly make our prediction
                data.train = crop_data[!(crop_data$"year" %in% year[pred.year[year_idx]]),]


                # data.test is the data frame containing the data used to test our model fit
                data.test = crop_data[crop_data$"year" %in% test.year,]


                # If the models use evi or lst, then refine the training and testing data frames to exclude those values
                # such that evi or lst is null
                if (uses_evi[formula_idx] == "Y")
                {
                    data.train <- data.train[!is.na(data.train$"evi5"),]
                    data.test <- data.test[!is.na(data.test$"evi5"),]
                }

                if (uses_lstmax[formula_idx] == "Y")
                {
                    data.train <- data.train[!is.na(data.train$"lstmax5"),]
                    data.test <- data.test[!is.na(data.test$"lstmax5"),]
                }

                # In what follows, we use the assumption that
                # tave5 is null iff precip5 is null iff tave5 is null
                # and that any one variant of a predictor (see the readme in the main directory) is null iff all other variants are null
                # This is at least potato specific and possibly applicable to other crops
                # But that assumption must be checked using examineData.py

                data.train <- data.train[!is.na(data.train$'tave5'),]
                data.test <- data.test[!is.na(data.test$'tave5'),]



                model_function <- NULL

                if (fitting_functions[formula_idx] == "lm")
                {
                    model_function <- lm(as.formula(model_formulas[formula_idx]), data=data.train)

                }
                else if (fitting_functions[formula_idx] == "lmer")
                {
                    model_function <- lmer(as.formula(model_formulas[formula_idx]), data=data.train, control = lmerControl(optimizer ="Nelder_Mead"))
                }


                # We want the testing data frame to only include those entries whose FIPS codes also occurred in the training data frame
                # We additionally want those FIPS codes that not only occurred in the training data frame but whose yield entries were not null
                if (uses_FIPS[formula_idx] == "Y")
                {
                    non_na_entries <- data.train[!(is.na(data.train$'yield')),]
                    data.test <- data.test[data.test$"FIPS" %in% non_na_entries$"FIPS",]
                }



                # For the year (startingYear + 14) that we perform LOO prediction by excluding -- if this
                # does indeed take place -- we save some attributes. For example, we store the
                # coefficients of the fitted function and we make some diagnostic plots as well.
                # If this year does not exist, then we do not make such plots.
                if (year_idx == 14)
                {
                    s <- capture.output(summary(model_function))
                    coeff <- capture.output(coef(model_function))
                    coeff_mean <- capture.output(coef(summary(model_function)))
                    csv_name <- paste0(yield_prediction_csv)
                    csv_name <- substr(csv_name, 3, nchar(csv_name))

                    # Make a name for the file where we will save the model attributes for the model
                    # obtained by performing LOO prediction by excluding year 2016.

                    diagnosticFileName <- paste0('./coefficients_', csv_name, model_names[formula_idx],'.txt')
                    write(s, diagnosticFileName, append=TRUE)
                    write("\n_________________\n",diagnosticFileName, append=TRUE)
                    write(coeff, diagnosticFileName, append=TRUE)
                    write("\n_________________\n",diagnosticFileName, append=TRUE)
                    write(coeff_mean, diagnosticFileName, append=TRUE)

                    # Make a name for the file where we will save a few plots
                    plotFile <-  paste0(model_names[formula_idx], "%03d.png")
                    png(filename=plotFile)
                    plot(model_function,ask=FALSE)
                    dev.off()
                }







                # Assign the variable currently called data.test to a variable whose name is the concatenation of "data.test" and test.year
                assign(paste0("data.test",test.year), data.test)

                # Assign a variable whose name will be the concatenation of func.pred and test.year a vector whose length is the length of the previous variable
                # (which is really a data frame)

                assign(paste0("func.pred",test.year), rep(NA,dim(get(paste0("data.test",test.year)))[1]))

                # Assign to this previous variable the predictions obtained by predicting the model function on the test data frame
                assign(paste0("func.pred",test.year), predict(model_function,get(paste0("data.test",test.year))))
                #+ yearly.means[which(crop_data[, 1] %in% test.year & crop_data$State %in% test_region)])


            }



            # CROP PARAMETER
            # You need to change the testing years and prediction years in the code below depending to include as many entries as there are years of data past 2003 for a particular crop. For example, tomato data runs from 2003 to 2017, whereas potato data runs from 2000 to 2016.
            # Make one data frame by binding together the test data frames from 2003 to 2016
            allTestData <- rbind.data.frame(data.test2003,data.test2004,data.test2005,data.test2006,data.test2007,data.test2008, data.test2009, data.test2010, data.test2011, data.test2012, data.test2013, data.test2014, data.test2015, data.test2016)

            # CROP PARAMETER
            # Make one vector by binding together the results of predicting on test data frames from 2003 to 2016
            predictions[[formula_idx]] <- c(func.pred2003,func.pred2004,func.pred2005,func.pred2006,func.pred2007,func.pred2008, func.pred2009, func.pred2010, func.pred2011, func.pred2012, func.pred2013, func.pred2014, func.pred2015, func.pred2016)
            predictionFrame <- data.frame(predictions[[formula_idx]])


            # Combine the predictionFrame data frame with allTestData's data frame and then save it with the name model_name[formula_idx]
            # This is done because if this code executes to completion, then it saves a dataframe containing the prediction results for all tested models in the model
            # experiment; if the code fails to execute to completion however, failing at some model within the model experiment, then all previous models will have
            # been saved. Each of the previous models will have been saved to a data frame whose data frame name is the model name
            write.csv(data.frame(predictionFrame, allTestData), model_names[[formula_idx]])
            endTime <- Sys.time()
            print(endTime - startTime)


        }



        # Turn the predictions matrix into a data frame
        df <- data.frame(predictions)
        colnames(df) <- model_names

        # allData is the combination of all the test data and the prediction data obtained from the test data
        allData <- data.frame(allTestData, df)



        basic_data <- c("year","State","FIPS","yield_ana", "yield", "area")
        desired_data <- c(basic_data, model_names)
        yield_prediction <- subset(allData, select = desired_data)



        # At present, our predictions are only for the yield anomaly
        # Now we need to add back the yield trend to get the actual yield prediction

        trend_function <- lm(yield ~ year + I(year^2), data=crop_data) # Use quadratic trends
        yearly.means <- predict(trend_function, yield_prediction)
        for (i in 1:length(model_names))
        {
            yield_prediction[,model_names[[i]]]  <- yield_prediction[,model_names[[i]]] + yearly.means
        }


        write.csv(yield_prediction, yield_prediction_csv)

        # We previously made temporary CSVs; this was done so that
        # the model configurations that were successfully predicted upon would be saved even if not all model configurations could be predicted upon.
        # If the code reaches this point in execution, then this danger of not all model configurations being predicted upon has become foregone and we
        # can delete the previous temporary files

        for (j in 1:length(model_names))
        {
            file.remove(model_names[[j]])
        }
        calculateRMSE(yield_prediction_csv, rmse_csv)





    }
}

# Main method
options(warn=1)

#CROP PARAMETER
crop_data_csv <- read.csv("../dataFiles/potato_with_anomaly.csv")
#crop_data_csv <- read.csv("../dataFiles/tomato_with_anomaly.csv")
yield_prediction_csv <- "./yan_combinations_potato.csv"
rmse_csv <- "./yan_combinations_potato_rmse.csv"
initialize(crop_data_csv, yield_prediction_csv, rmse_csv)
