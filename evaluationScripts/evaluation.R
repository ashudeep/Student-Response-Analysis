classContingency <- function(predicted, actual, value) {
  tp <- sum ( (predicted == value) & (predicted == actual) )
  fp <- sum ( (predicted == value) & (predicted != actual) )
  tn <- sum ( (predicted != value) & (actual != value) )
  fn <- sum ( (predicted != value) & (actual == value) )
  c(tp=tp, fp=fp, tn=tn, fn=fn)
}

globalContingencyTable <- function (predicted, actual, valueSet=NULL) {
  # if specified, use the order from valueSet; otherwise sort the actual values
  if (is.null(valueSet)) {
    values = sort(unique(actual))
  } else {
    values = valueSet
  }

  data.frame(sapply(values, FUN=function(val){classContingency(predicted, actual, val)}))

}


weightedAverageFromContingency <- function(contingency.table, value.set, FUN) {
  ## in the contingency table, each column is tp+fp+tn+fn for a given class, and should add up to the same number = the total number of instances
  n.items = sum(contingency.table[,1])
  ## weight(c) = (N(c))/N
  sum( sapply(valueSet, FUN=function(val) { (expectedFromContingency(contingency.table, val)/n.items) * do.call(FUN, list(contingency.table, val)) } ) )
}
    

# For each class, the number of expected instances = tp + fn; 
expectedFromContingency <- function(contingency.table, class) {
  contingency.table["tp", val] + contingency.table["fn", val]
}

precisionFromContingency.class <- function(contingency.table, class) {

  if (! ( class %in% colnames(contingency.table) ) ) {
    stop(sprintf('Class name %s is not of the class names in the contingency table'), class)
  }

  sumTpFp <- sum(contingency.table["tp",class] + contingency.table["fp", class])
    
  if (sumTpFp == 0) {
    # nothing predicted.
    if (expectedFromContingency(contingency.table, class) == 0) {
      # nothing expected -- return 1 by convention
      1
    } else {
      0
    }
  } else {
    contingency.table("tp", class)/ sumTpFp
  }
}

  
precisionFromContingency <- function(contingency.table, class, valueSet=NULL) {
  if (is.null(valueSet)) {
    valueSet = colnames(contingency.table)
  }
  if (class == "macro") {
    mean(sapply(valueSet, FUN=function(val) { precisionFromContingecy.class(contingency.table, val) }))
  } else if (class == "micro") {
    sum(contingency.table["tp",])/sum(contingency.table["tp",]+contingency.table["fp",])
  } else if (class == "weighted") {
    weightedAverageFromContingency(contingency.table, valueSet, precisionFromContingency.class)
  } else {
    precisionFromContingency.class(contingency.table, class)
  }
}



recallFromContingency.class <- function(contingency.table, class) {

  if (! ( class %in% colnames(contingency.table) ) ) {
    stop(sprintf('Class name %s is not of the class names in the contingency table'), class)
  }

  
  sumTpFn <- sum(contingency.table["tp",class] + contingency.table["fn", class])
    
  if (sumTpFn == 0) {
    # nothing expected.
    if (contingency.table["tp",class] == 0) {
      # nothing predicted -- return 1 by convention
      1
    } else {
      0
    }
  } else {
    contingency.table("tp", class)/ sumTpFn
  }
}

recallFromContingency <- function(contingency.table, class, valueSet=NULL) {
  if (is.null(valueSet)) {
    valueSet = colnames(contingency.table)
  }
  if (class == "macro") {
    mean(sapply(valueSet, FUN=function(val) { recallFromContingecy.class(contingency.table, val) }))
  } else if (class == "micro") {
    sum(contingency.table["tp",])/sum(contingency.table["tp",]+contingency.table["fn",])
  } else if (class == "weighted") {
    weightedAverageFromContingency(contingency.table, valueSet, recallFromContingency.class)
  } else {
    recallFromContingency.class(contingency.table, class)
  }
}


fmeasureFromContingency.class <- function(contingency.table, class) {
  
  if (! ( class %in% colnames(contingency.table) ) ) {
    stop(sprintf('Class name %s is not of the class names in the contingency table'), class)
  }

  prec <- precisionFromContingency.class(contingency.table, class)
  rec <- recallFromContingency.class(contingency.table, class)
  
  if ((prec == 0) && (rec == 0)) {
    # if both precision or recall is 0, return 0 by convenion
    0
  } else {
    (2 * prec * rec) / (prec + rec)
  }
}


fmeasureFromContingency <- function(contingency.table, class, valueSet=NULL) {
  if (is.null(valueSet)) {
    valueSet = colnames(contingency.table)
  }
  if (class == "macro") {
    mean(sapply(valueSet, FUN=function(val) { fmeasureFromContingecy.class(contingency.table, val) }))
  } else if (class == "micro") {
    ## calculation matching Weka's unweightedMicroFmeasure, and also tsoumakas et al. (2009), mining multi-label data
    2*sum(contingency.table["tp",])/(2*sum(contingency.table["tp",]) + sum(contingency.table["fn",]) + sum(contingency.table["fp",]))   
  } else if (class == "weighted") {
    weightedAverageFromContingency(contingency.table, valueSet, fmeasureContingency.class)
  } else {
    recallFromContingency.class(contingency.table, class)
  }
}

    
precision <- function(predicted, actual, value) {
  sumTpFp <- sum(predicted==value)

  if (sumTpFp == 0) {
    # nothing predicted.
    if (sum(actual==value) == 0) {
      # nothing expected -- return 1 by convention
      1
    } else {
      0
    }
  } else {
    sum( (predicted == value) & (predicted == actual) ) /  sumTpFp
  }



}

recall <- function(predicted, actual, value) {
  sumTpFn <- sum(actual == value)
  if (sumTpFn == 0) {
    # nothing expected. 0 by convention if nothing predicted as well, or 1 otherwise
    if (sum(predicted==value) == 0) {
      1
    } else {      
      0
    }
  } else {
    sum( (predicted == value) & (predicted == actual) ) /  sumTpFn
  }
}

fmeasure <- function( predicted, actual, value ) {
  prec <- precision(predicted, actual, value)
  rec <- recall( predicted, actual, value)
  if ((prec == 0) && (rec == 0)) {
    # if both precision or recall is 0, return 0 by convenion
    0
  } else {
    (2 * prec * rec) / (prec + rec)
  }
}

classAccuracy <- function (predicted, actual, value) {
  # !xor returns us true if either they are both equal to value, or both unequal to specified value
  sum(!xor(predicted == value, actual == value))/length(predicted)
}


perClassEval <- function (predicted, actual, FUN=fmeasure, valueSet=NULL) {
  # if specified, use the order from valueSet; otherwise sort the actual values
  if (is.null(valueSet)) {
    values = sort(unique(actual))
  } else {
    values = valueSet
  }
  sapply(values, FUN=function(x){do.call(FUN, list(predicted, actual, x))})
}

macroav <- function (predicted, actual, FUN=fmeasure, valueSet=NULL, macroav.subset=NULL) {
    
  fvals <- perClassEval(predicted, actual, FUN=FUN, valueSet=valueSet)
  if (is.null(macroav.subset)) {    
    mean(fvals)
  } else {
    if ( length(setdiff(macroav.subset, names(fvals))) > 0 ){
      stop(sprintf("Invalid macroav.subset passed into macroav: %s. Allowed values are: %s\n", macroav.subset, names(fvals)))
    }
    mean(fvals[macroav.subset])
  }
}

accuracy <- function (predicted, actual) {
  sum(predicted == actual)/length(actual)
}

## Compute microaverage. Results has to be output from perClassEval, a simple vector with names
## classes is just a list of all class instances (i.e., actual in perClassEval) which will produce counts
microaverage <- function(results, classInstanceList, valueSet=NULL) {
  if (is.null(valueSet)) {
    value.set = sort(unique(classInstanceList))
  } else {
    value.set = valueSet
  }
  class.counts <- as.data.frame(table(classInstanceList, dnn=c("label")), responseName="count")
  # by doing this merge, we will effectively add

  if (length(setdiff(class.counts$label,value.set)) > 0) {
    warning("In microaverage, I have more possible classes than specified by value.set. The result will be unreliable")
  }
  
  missing.labels = setdiff(value.set, class.counts$label)
  if (length(missing.labels) > 0) {
    class.counts <- rbind(class.counts, data.frame(label=missing.labels, count=0))
  }
  ## This will effectively sort class counts
  summary.table <- merge(data.frame(score=results), class.counts, by.x="row.names", by.y="label", all.x=FALSE, all.y=TRUE)
  summary.table$score <- replace(summary.table$score, (is.na(summary.table$score) & is.na(summary.table$count)), 0)
  summary.table$count <- replace(summary.table$count, is.na(summary.table$count), 0)
  sum(summary.table$score*summary.table$count)/length(classInstanceList)
}
  

collapse.3class <- function (class) {
  if (class == "correct") {
    "correct"
  } else if (class == "non_domain") {
    "non_domain"
  } else if (class == "uninterpretable") {
    "uninterpretable"
  } else {
    "incorrect"
  }
}

semeval.evaluation <- function( predicted, actual, valueSet=NULL, macroav.subset=NULL) {
  # define valueSet here so that everyone uses the same one
  # if specified, use the order from valueSet; otherwise sort the actual values
  if (is.null(valueSet)) {
    values = sort(unique(actual))
  } else {
    values = valueSet
  }
  
  prec <- perClassEval( predicted, actual, FUN=precision, valueSet=values )
  rec <- perClassEval( predicted, actual, FUN=recall, valueSet=values )
  f <- perClassEval( predicted, actual, FUN=fmeasure, valueSet=values )
  

  res <- data.frame( precision=prec, recall=rec, fmeasure=f)

  if (is.null(macroav.subset)) {
    macroav <- colMeans(res)
  } else {
    if ( length(setdiff(macroav.subset, values)) > 0 ) {
      stop(sprintf("Invalid macroav.subset passed into macroav: %s. Allowed values are: %s\n", macroav.subset, values))
    }
    macroav <- colMeans(res[macroav.subset, ])
  }

  microav <- apply(res,2,function(x){microaverage(x, actual, valueSet=valueSet)})
  
  res <- rbind(res, macroaverage=macroav)
  res <- rbind(res, microaverage=microav)
  ### Overall accuracy is actually micro-averaged recall!
  res
}


feedback.evaluation <- function( predicted, actual ) {

  ## first we do optimistic
  optimistic <- list(
                     tp = sum( (predicted == "correct") & (actual == "correct")),
                     tn = sum( (predicted != "correct") & (actual != "correct")),
                     fp = sum( (predicted == "correct") & (actual != "correct")),
                     fn = sum( (predicted != "correct") & (actual == "correct")))

  pessimistic <- list(
                     tp = sum( (predicted == actual) & (actual != "correct")),
                     tn = sum( (predicted == actual) & (actual == "correct")),
                     fp = sum( (predicted != actual) & (actual == "correct")),
                     fn = sum( (predicted != actual) & (actual != "correct")))

  optimistic.stats <- conf.stats(optimistic$tp, optimistic$tn, optimistic$fp, optimistic$fn)
  pessimistic.stats <- conf.stats(pessimistic$tp, pessimistic$tn, pessimistic$fp, pessimistic$fn)

  table <- data.frame( rbind(optimistic.stats, pessimistic.stats) )
  rownames(table) <- c("optimistic", "pessimistic")
                             
  
  list(
       table = table,
       optimistic = optimistic,
       pessimistic = pessimistic
       )
}

conf.stats <- function (tp, tn, fp, fn) {
  prec = tp/(tp+fp)
  rec = tp/(tp+fn)
  data.frame(precision = c(prec), recall = c(rec), fmeasure = c(2 * prec * rec / (prec + rec)) )
}


# Return confusion matrix for the predicted/actual combination
confusion.matrix <- function( predicted, actual, valueSet = NULL, drop.unint=FALSE) {
  if (is.null(valueSet)) {
    valueSet <- sort(unique(actual))
  }
  if (drop.unint) {
    actualValue = factor(actual[predicted != "uninterpretable"], valueSet)
    predictedValue=factor(predicted[predicted != "uninterpretable"],levels=valueSet)    
  } else {
    actualValue=factor(actual,levels=valueSet)
    predictedValue=factor(predicted,levels=valueSet)
  }
  table(predictedValue, actualValue,deparse.level=2)
}

confusion.scores <- function( predicted, actual, valueSet = NULL, drop.unint = FALSE) {
  if (drop.unint) {
    value.set <- valueSet[valueSet != "uninterpretable"]
  } else {
    value.set <- valueSet
  }
  cmf <- as.data.frame(confusion.matrix(predicted, actual, valueSet = value.set, drop.unint = drop.unint ))
  errors <- cmf[cmf$predictedValue != cmf$actualValue,]
  rn <- paste("predicted",errors$predictedValue,"actual",errors$actualValue,sep=".")
  data.frame(Freq=errors$Freq, row.names=paste("predicted",errors$predictedValue,"actual",errors$actualValue,sep="."))
}
  
participant.scores <- function( frame, FUN=function(x){semeval.evaluation(x$BeetleAuto, x$BeetleCore)} ) {
  mergeSessionList(lapply(frame, FUN=FUN))
}

unint.scores <- function( predicted ) {
  # For now, just 1 score - percent uninterpretable
  unint = sum(predicted == "uninterpretable")/length(predicted)
  data.frame(unint=c(unint), row.names=c("percentage"))
}


run.evaluation <- function ( systemFile, goldFile, mode="5way", subsets=NULL, macroav.exclude=NULL ) {

  if (mode=="5way") {
    value.order = c("correct","partially_correct_incomplete","contradictory","irrelevant","non_domain")
  } else if (mode=="3way") {
    value.order = c("correct","contradictory","incorrect")
  } else if (mode=="2way") {
    value.order = c("correct","incorrect")
  } else if (mode=="partEnt") {
    value.order = c("Expressed","Unaddressed")
  } else {
    stop(sprintf("Incorrect mode value %s. Allowed values are: 5way, 3way, 2way, partEnt", mode))
  }

  cat(sprintf("Reading file %s\n",systemFile),file=stderr())
  # The system file is 2 columns, no headers, just question id and answer ID
  system.raw <- read.table(systemFile, header=TRUE, row.names=1, stringsAsFactors = FALSE, sep="\t")
  cat(sprintf("... success\n", systemFile),file=stderr())

  # The gold file has a somewhat more complex structure, with multiple columns
  cat(sprintf("Reading file %s\n",goldFile),file=stderr())
  gold.raw <- read.table(goldFile, header=TRUE, row.names=1, stringsAsFactors = FALSE, sep="\t")
  cat(sprintf("... success\n", goldFile),file=stderr())

  if (nrow(gold.raw) != nrow(system.raw)) {
      stop( paste ("Gold and system data have different length: ", nrow(gold.raw), "and", nrow(system.raw), ". Check that you passed in correct files") )
  }

  gold <- gold.raw[order(rownames(gold.raw)),, drop=FALSE]
  system <- system.raw[order(rownames(system.raw)),, drop=FALSE]


  if (is.null(subsets)) {
    # we are not looking for subsets, so we will just pretend
    # make sure the column is inserted at the beginning, because last one is the class
    gold <- cbind(testSet=c("none"), gold);
    test.sets <- c("none")
  } else {
    if (! ("testSet" %in% colnames(gold)) ) {
      stop(sprintf("The gold file %s does not have a testSet column, yet subset argument is specified. Aborting.\n", goldFile))
    }
    allowed.subsets <- unique(gold$testSet)
    if ( length(setdiff(subsets,allowed.subsets)) > 0 ) {
      stop( sprintf("Subsets %s not found in the testSet in file %s. Allowed test sets are %s\n", setdiff(subsets,allowed.subsets), goldFile, allowed.subsets) )
    }
    test.sets <- subsets
  }

  cat("\n")
  result.list <- list();
  for (test.set in test.sets) {
    gold.subset <- gold[gold$testSet == test.set,,drop=FALSE]
    system.subset <- system[gold$testSet == test.set,,drop=FALSE]
    
    actual = gold.subset[, length(colnames(gold.subset))]
    predicted = system.subset[, length(colnames(system.subset))]

    if (!is.null(macroav.exclude)) {
      macroav.subset <- setdiff(value.order, macroav.exclude[[test.set]])
    } else {
      macroav.subset <- NULL
    }
    
    class.eval <- semeval.evaluation(predicted, actual, valueSet=value.order, macroav.subset=macroav.subset)
    
    if (mode != "partEnt") {
      feedback.eval <- feedback.evaluation(predicted, actual)
    }
    
    #  write.table(rbind(class.eval, feedback.eval$table), quote=FALSE)

    if (!is.null(subsets)) {
      cat(sprintf("Subset %s\n", test.set))
    }
    write.table(format(class.eval, digits=3), sep='\t', col.names=NA, quote=FALSE)
    cat("\n")
    result.list[[test.set]] <- class.eval
  }
    
  if (is.null(subsets)) {
    # no subsets specified, return the single element
    result.list[["none"]]
  } else {
    result.list
  }
}




writeXMLResults <- function(run, results, xmlBuffer) {
  xmlBuffer$addTag("run", attrs=c(name=run), close=FALSE)

  if (is.data.frame(results)) {
    # no subsets
    xmlBuffer$addTag("subset", attrs=c(name="all"), close=FALSE)
    writeXMLResults.singleset(run, results, xmlBuffer)
    xmlBuffer$closeTag()
  } else {
    for (subset in names(results)) {
      xmlBuffer$addTag("subset", attrs=c(name=subset), close=FALSE)
      writeXMLResults.singleset(run, results[[subset]], xmlBuffer)
      xmlBuffer$closeTag()
    }
  }
  
  xmlBuffer$closeTag()
  xmlBuffer

}

writeXMLResults.singleset <- function(run, results, xmlBuffer) {
  
  print.results <- apply(results, c(1,2), FUN = function(x){sprintf("%.2f%%",x*100)})
  microav <- print.results["microaverage",]
  macroav <- print.results["macroaverage",]
  class.results <- print.results[(rownames(print.results)!="microaverage") & (rownames(print.results) != "macroaverage"), ]


  xmlBuffer$addTag("microaverage", attrs=microav)

  xmlBuffer$addTag("macroaverage", attrs=macroav)

  xmlBuffer$addTag("perClass", close=FALSE)

  classes <- rownames(class.results)
  for (class in classes) {
    xmlBuffer$addTag(class, attrs = class.results[class,])
  }

  xmlBuffer$closeTag()

  xmlBuffer
}

batch.evaluation <- function ( ..., goldFile=NULL, xmlOut=NULL, mode="5way" ) {
  library(XML)
  
  if (is.null(goldFile)) {
    stop("goldFile not specified\n")
  }

  if (is.null(xmlOut)) {
    stop("xmlout not specified")
  }

  xmlBuffer <- xmlOutputDOM("teamResults")

  for (systemFile in list(...)) {
    res <- run.evaluation( systemFile, goldFile, mode=mode )
    writeXMLResults(systemFile, res, xmlBuffer)
  }
  saveXML(xmlBuffer$value(), file=xmlOut)  
}


semeval.challenge.evaluation <- function ( beetle.files=NULL, beetle.gold = NULL, seb.files=NULL, seb.gold=NULL, xmlOut=NULL, mode="5way", team="unknown" ) {
  library(XML)

  if ((length(beetle.files) > 0) & is.null(beetle.gold)) {
    stop("beetle.files are specified, but beetle.gold is missing")
  }

  if ((length(seb.files) > 0) & is.null(seb.gold)) {
    stop("seb.files are specified, but seb.gold is missing")
  }
  
  if (is.null(xmlOut)) {
    stop("xmlout not specified")
  }

  xmlBuffer <- xmlOutputDOM("teamResults", attrs=c(name=team))

  if (length(beetle.files) > 0) {
    xmlBuffer$addTag("dataset", attrs=c(name="beetle"), close=FALSE);
    for (beetle.file in beetle.files) {
      res <- run.evaluation( beetle.file, beetle.gold, mode=mode, subsets=c("unseen-answers","unseen-questions") )
      writeXMLResults( basename(beetle.file), res, xmlBuffer )
    }
    xmlBuffer$closeTag()
  }

  if (length(seb.files) > 0) {
    xmlBuffer$addTag("dataset", attrs=c(name="sciEntsBank"), close=FALSE);
    for (seb.file in seb.files) {
      res <- run.evaluation( seb.file, seb.gold, mode=mode, subsets=c("unseen-answers", "unseen-questions", "unseen-domains"),
                            macroav.exclude=list(`unseen-answers`=c("non_domain"), `unseen-questions`=c("non_domain"))
#                            macroav.exclude=NULL
                            )
      writeXMLResults( basename(seb.file), res, xmlBuffer )
    }
    xmlBuffer$closeTag()
  }
  
  saveXML(xmlBuffer$value(), file=xmlOut)  
}



semeval.pilot.evaluation <- function ( pilot.files, pilot.gold,  xmlOut, team="unknown" ) {
  library(XML)

  xmlBuffer <- xmlOutputDOM("teamResults", attrs=c(name=team))

  xmlBuffer$addTag("dataset", attrs=c(name="pilotentailment"), close=FALSE);
  for (pilot.file in pilot.files) {
      res <- run.evaluation( pilot.file, pilot.gold, mode="partEnt", subsets=c("unseen-answers", "unseen-questions", "unseen-domains"),
                            macroav.exclude=NULL
                            )
      writeXMLResults( basename(pilot.file), res, xmlBuffer )
    }
  xmlBuffer$closeTag()
    
  saveXML(xmlBuffer$value(), file=xmlOut)  
}

    
