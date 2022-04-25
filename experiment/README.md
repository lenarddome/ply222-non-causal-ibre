# minimal design IBRE

## Files

*   experiment.js {javascript} building components of the experiment
*   index.html {webpage} front-end webpage running the experiment
*   .eslintrc.js {javascript} a file I use with neomake for code style and code
    benchmark-

## Notes from Andy

*   When setting up a repo on willslab, it's crucial to type `umask 0002` prior
    to `git init`. Otherwise, only you can push changes to the repo. I logged in as
    root and think I was able to fix things, but it led to some head scratching :-)

*   I made some instruction tweaks, see `git log`

*   It would be worth forewarning the participants that the test phase has
    multiple blocks of X trials. \[DONE]

*   How do they withdraw post-completion? Don't they need their participant number?
    LD: We will use the unique SONA id that JATOS can exract from the URL parameters.
    I thought it would be better, becasue participants don't have to remember them
    and we don't have to worry about it (in terms of ethics). This unique code
    is available until participants leave SONA.

*   Could you please write a brief codebook for the output data file? \[DONE]

*   Are you happy that the data gets saved to JATOS with the correct unique
    participant ID?
    LD: Yes, that is okay. Only I will have access to it and the data will be
    anonymised. Or did you mean something else?

## Local Debugging:

You can finish a block by pressing 'backspace'. At the end, the data that
will be uploaded to JATOS is printed in the console (press F12 to see).

### CORS and SOP errors

If running on a local machine, rather than from a web server, you'll need to make the following changes:

#### Firefox

Enter `about:config` and set `privacy.file_unique_origin` to false. Change it
back to true once you're finished. See here for more detail:
[mozilla](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS/Errors/CORSRequestNotHttp).

It might be worth creating a separate Firefox profile just for this debugging.
It will separate any data relating to your every-day profile.

#### Chromium

Start up chromium (available via snap in Linux) with the following command
in the experiment directory:

```bash
chromium --disable-web-security --user-data-dir="[some directory here]"
```

More info can be found on [StackExchnage](https://stackoverflow.com/questions/3102819/disable-same-origin-policy-in-chrome),

#### Credit granting on SONA

SONA generates its unique ID that can be accessed by JATOS as an URL query
paremeter. You need to add `id=%SURVEY_CODE%` to the URL provided to participants.

    http://localhost:9000/publix/50/start?batchId=47&personalSingleWorkerId=506&id=%SURVEY_CODE%

This can be accessed via JATOS and used to send a ping to SONA by this ID. See
the [tech office guide](https://www.psy.plymouth.ac.uk/home/Documents/SONA_JATOS.pdf).
