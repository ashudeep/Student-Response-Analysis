Given a question, a known correct "reference answer" and a 1- or 2-sentence "student answer", the main task consists of assessing the correctness of a student’s answer at different levels of granularity, namely:

- 5-way task, where the system is required to classify the student answer according to one of the following judgments:
  correct,
  partially correct but incomplete,
  contradictory (it contradicts content in the reference answer ),
  irrelevant (it does not contain information directly relevant to the answer),
  not in the domain (e.g., expressing a request for help).
- 3-way task, where the system is required to classify the student answer according to one of the following judgments:
  correct,
  contradictory (if it contains information contradicting the content of the reference answer),
  incorrect (conflating the categories partially correct but incomplete, irrelevant  and not in the domain in the 5-way classification)
- 2-way task, where the system is required to classify the student answer according to one of the following judgments:
  correct,
  incorrect (conflating the categories contradictory and incorrect in the 3-way classification)

To run the code:

1.) For 5 way task, go to the folder semevalFormatProcessing-5way and run script.sh

2.) For 3 way task, go to the folder semevalFormatProcessing-3way and run script.sh

3.) For 2 way task, go to the folder semevalFormatProcessing-2way and run script.sh

