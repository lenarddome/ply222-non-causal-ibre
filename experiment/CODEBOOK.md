# CODEBOOK

Includes a table with the variable descriptions.

## VARIABLE TABLE

| variables          | meaning                                                                           | values                |
| ------------------ | --------------------------------------------------------------------------------- | --------------------- |
| "rt"               | reaction time                                                                     | numeric               |
| "correct"          | [always false in this experiment] correct (true) or incorrect (false) response    | boolean               |
| "stimulus"         | the physical stimuli displayed (words of symptoms)                                | string                |
| "key_press"        | the response key pressed                                                          | numeric JS char codes |
| "keys"             | the counterbalanced response keys, where first is common and second is rare       | numeric JS char codes |
| "symptom1"         | first abstract feature                                                            | string                |
| "symptom2"         | second abstract feature                                                           | string                |
| "key"              | [training] the correct key for the current stimulus                               | JS char codes         |
| "category"         | [training] the correct category (common or rare)                                  | string                |
| "phase"            | the current phase (training, test)                                                | string                |
| "trial"            | the number of the current trial within phase                                      | numeric               |
| "include"          | whether to include trial in final data set <sup>[1](#NOTES)</sup>                 | boolean               |
| "trial_type"       | the JSPsych plugin used to run the trial                                          | string                |
| "trial_index"      | The index of the current trial component across the whole experiment              | numeric               |
| "time_elapsed"     | The number of milliseconds since the start of the experiment when the trial ended | numeric               |
| "internal_node_id" | ID of the internal TimelineNode                                                   | string                |
| "ppt"              | unique participant ID from SONA                                                   | string                |
| "session"          | date and hour                                                                     | numeric               |
| "abresp"           | the abstract response converted from key_press (common, rare, none)               | string                |

## NOTES

1.  This only affects the uploaded csv file. The unfiltered JSON file is also
    submitted to the JATOS server.
