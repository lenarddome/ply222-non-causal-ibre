// declare all variables
var trials;
let symptoms;
let disease_keylist;
let acc = 0;
let tmp;
var resp = [];
let permArr = [];
let usedChars = [];
var trials = [];
var testTrials = [];
var testBlock = [];
var trainingCounter = [];

/* ******************************************
 * Create components of the experiment
******************************************* */

/** permute - produce permutations of array with no repeats
 * taken from https://stackoverflow.com/a/9960925/7214634
 * @param {array} input array to be permuted
 * @return {array} all possible permutations of elements from array
 */
function permute(input) {
  let i; let ch;
  for (i = 0; i < input.length; i++) { //   loop over all elements
    ch = input.splice(i, 1)[0]; // 1. pull out each element in turn
    usedChars.push(ch); //   push this element
    if (input.length == 0) { // 2. if input is empty, we pushed every element
      permArr.push(usedChars.slice()); //   so add it as a permutation
    }
    permute(input); // 3. compute the permutation of the smaller array
    input.splice(i, 0, ch); // 4. add the original element to the beginning
    //   making input the same size as when we started
    //   but in a different order
    usedChars.pop(); // 5. remove the element we pushed
  }
  return permArr; // return, but this only matters in the last call
}

// create physical stimuli
symptoms = ['square', 'circle', 'triangle', 'hexagon', 'diamond'];
symptoms = jsPsych.randomization.shuffle(symptoms);

// create html alt codes for fonts
shapeCodes = {
  square: '&#x23F9',
  circle: '&#x23FA',
  triangle: '&#x25B2',
  hexagon: '&#x2B23',
  diamond: '&#x25C6',
};

// key codes: 88 is X and 89 is Y key
// first element is always common, second element is always rare
disease_keylist = [80, 81];
disease_keylist = jsPsych.randomization.shuffle(disease_keylist);

// inter-trial interval

const intertrial = {
  type: 'html-keyboard-response',
  stimulus: '',
  trial_duration: 500,
  response_ends_trial: false,
  choices: jsPsych.NO_KEYS,
};

// instructions for training phase
const instructionTraining = {
  type: 'html-keyboard-response',
  stimulus: ['<p style="display:inline-block;align:center;font-size:20pt;' +
    'width:60%"> In this phase, you will be shown various geometric shapes. ' +
    'These shapes can either be a circle &#x23FA, a triangle &#x25B2, a ' +
    'square &#x23F9, a hexagon &#x2B23, or a diamond &#x25C6. These shapes ' +
    'will appear in groups of three. Your task is to study and try ' +
    'to remember the shapes that appeared together.<br><br> You will ' +
    'see 5 blocks of 8 shape combinations - 40 overall. However, you will ' +
    'also be given the opportunity to skip this phase after the 16th shape ' +
    'combination at the end of the second block.<br><br>' +
    'You will need to press the spacebar after you studied each arrangement.' +
    'You can study each one for 10 seconds.' +
    '</p><br>Press \'p\' to continue.'],
  choices: ['p'],
};

// instructions for test phase
const instructionTest= {
  type: 'html-keyboard-response',
  stimulus: ['<p style="display:inline-block;align:center;font-size:20pt;' +
    'width:60%">' +
    'Well done on completing the first phase! Now, you will begin the test ' +
    'phase. In this phase of the experiment, you will be asked to complete ' +
    'each combination by adding one single shape. You can either pick a ' +
    symptoms[3] + ' ' + shapeCodes[symptoms[3]] + ' by pressing ' +
    String.fromCharCode(disease_keylist[0]) +
    ' or a ' + symptoms[4] + ' ' + shapeCodes[symptoms[4]] + ' by pressing ' +
    String.fromCharCode(disease_keylist[1]) + '.<br><br> This phase will have' +
    ' 5 blocks of 24 combinations to complete. You will have a chance' +
    ' to rest between blocks.' +
    '<br><br>Press \'p\' to continue.</p>'],
  choices: ['p'],
};

// welcome message
const welcome = {
  type: 'html-keyboard-response',
  stimulus: ['<p style = "font-size:48px;line-height:2;">' +
        'Welcome to the Experiment! <br> Please press \'space\'.</p>',
  ],
  choices: ['space'],
  on_start: function() {
    //const pptID = jatos.urlQueryParameters.id;
    //jsPsych.data.addProperties({ppt: pptID, session: sessionCurrent});
  },
};

// between block rest during test
const testRest = {
  type: 'html-keyboard-response',
  stimulus: ['<p style = "font-size:20px;line-height:2;width:600px ">' +
        'You have completed a block. Take a breath and press \'p\' ' +
        'on the keyboard when you are ready to continue</p>',
  ],
  choices: ['p'],
};

// remind people to press EXIT EXPERIMTENT button at the end
const creditReminder = {
  type: 'html-keyboard-response',
  stimulus: ['<h1>Point Granting</h1>' +
      '<p style="display:inline-block;align:center;font-size:20pt;' +
      'width:60%">In order to receive the allocated points after completing the experiment, ' +
      'you must read the debrief and click on the <strong> EXIT EXPERIMENT button</strong>.' +
      'Any point will be granted by redirecting you to the SONA website.' +
    '<br><br> Press \'p\' to continue.'],
  choices: ['p'],
};

// debrief
const debrief = {
  type: 'external-html',
  url: 'assets/debrief.html',
  cont_btn: 'exit',
  on_start: function() {
    const results = jsPsych.data.get().filter({include: true}).csv();
    // jatos.submitResultData(results);
    // jatos.uploadResultFile(results, sessionCurrent + '.csv')
    //    .then(() => console.log('File was successfully uploaded'))
    //    .catch(() => console.log('File upload failed'));
  },
};

// consent form

/* sample function that might be used to check if a subject has given
* consent to participate. If the button is clicked without checking the
* 'I agree' box, prompt participants to check it.
* taken from JSpsych external-html documentation
* @param {boolean} elem True or False boolean
*/
const checkConsent = function(elem) {
  if (document.getElementById('consent_checkbox').checked) {
    return true; // return true if it has been checked
  } else {
    alert('If you wish to participate, you must check the box next to' +
          ' the statement \'I agree to participate in this study.\'');
    return false;
  }
  return false;
};

const consent = {
  type: 'external-html',
  url: 'assets/consent.html',
  cont_btn: 'start',
  check_fn: checkConsent,
};

/* Create abstract design for both training and test phases */

const trainingItems = [['A', 'B', 'D'],
  ['A', 'B', 'D'],
  ['A', 'B', 'D'],
  ['A', 'C', 'E']]; // training trial types

const testItems = [['A'], ['B'], ['C'], ['A'], ['B'], ['C'],
  ['A', 'B'],
  ['B', 'A'],
  ['A', 'C'],
  ['C', 'A'],
  ['B', 'C'],
  ['C', 'B']];

/* *******************************************
 * ********* Create training phase ***********
 ******************************************* */

// permute trainingItems for counterbalancing
for (let i = 0; i < trainingItems.length; i++) {
  tmp = [];
  permArr = [];
  usedChars = [];
  tmp = permute(trainingItems[i]);
  trainingCounter.push(tmp);
}

// combine training blocks (randomize within blocks)
trials = trials.concat(jsPsych.randomization.shuffle(trainingCounter.flat()),
    jsPsych.randomization.shuffle(trainingCounter.flat()),
    jsPsych.randomization.shuffle(trainingCounter.flat()),
    jsPsych.randomization.shuffle(trainingCounter.flat()),
    jsPsych.randomization.shuffle(trainingCounter.flat()));


// combine test blocks (randomize within blocks)
for (let i = 0; i < 10; i++) {
  testTrials = testTrials.concat(
      jsPsych.randomization.shuffle(testItems));
}

const trainingBlock = []; // training matrix
let blk = 1; // block number

for (var i = 0; i < trials.length; i++) {
  // set up individual features
  const symptom1 = symptoms[trials[i][0].charCodeAt(0) - 65];
  const symptom2 = symptoms[trials[i][1].charCodeAt(0) - 65];
  const symptom3 = symptoms[trials[i][2].charCodeAt(0) - 65];
  // select correct response key and category based on current stimuli
  if (trials[i].includes('B')) {
    var correct = disease_keylist[0];
    var category = 'common';
  } else if (trials[i].includes('C')) {
    var correct = disease_keylist[1];
    var category = 'rare';
  }
  trainingBlock.push({
    type: 'categorize-html',
    // TODO: shape stimuli
    stimulus: ['<div class="row">' +
     '<img style="height:200px;margin:20px" src="./assets/' + symptom1 + '.png"></img>' +
     '<img style="height:200px;margin:20px" src="./assets/' + symptom2 + '.png"></img>' +
     '<img style="height:200px;margin:20px" src="./assets/' + symptom3 + '.png"></img></div><br><br>'],
    choices: ['space', 'z', 'l'],
    prompt: '<div style="margins:20px"><p style = "font-size:24px">' +
      'Press space to see the next item.' +
      '</p></div>',
    data: {
      symptom1: trials[i][0],
      symptom2: trials[i][1],
      symptom3: trials[i][2],
      stimulus: [symptom1, symptom2, symptom3],
      key: correct, // correct response key
      category: category, // stimuli category
      phase: 'training',
      trial: i + 1,
      include: true,
      block: blk,
    },
    key_answer: correct,
    show_stim_with_feedback: false,
    show_feedback_on_timeout: false,
    correct_text: '',
    incorrect_text: '',
    feedback_duration: 500,
    trial_duration: 5000,
    timeout_message: '<p style = "font-size:30px">Please respond faster!</p>',
    on_finish: function(data) {
      // decode responses into common or rare
      if (disease_keylist.indexOf(data.key_press) === 0) {
        resp = 'common';
      } else if (disease_keylist.indexOf(data.key_press) === 1) {
        resp = 'rare';
      } else {
        resp = 'none';
      };
      data.abresp = resp; // record abstract response
      if (data.key_press === 8) {
        jsPsych.endCurrentTimeline(); // end if backspace is pressed
      }
    },
  });
  trainingBlock.push(intertrial); // intertrial interval
  if (i > 1 && i < 8 && (i + 1) % 8 === 0) {
    trainingBlock.push({
      type: 'html-keyboard-response',
      stimulus: ['<p style = "font-size:24px;line-height:2;width:600px ">' +
            'You have completed a training block. <br>Take ' +
            'a breath and press p when you are ready to continue.</p>'],
      choices: ['p'],
    });
    blk += 1;
  }
  if (i > 1 && i > 8 && (i + 1) % 8 === 0) {
    trainingBlock.push({
      type: 'html-keyboard-response',
      stimulus: ['<p style = "font-size:24px;line-height:2;width:800px ">' +
            'You have completed a training block. Now you have the ' +
            'option to skip the rest of the training phase and move straight ' +
            'to the test phase. If you think you need some more time, you ' +
            'can continue training and study more items.<br><br>Take ' +
            'a breath and press p if you wish to continue, or press ' +
            'enter if you wish to skip to the test phase.</p>'],
      choices: ['p', 'enter'],
      on_finish: function(data) {
        if (data.key_press === 13) {
          jsPsych.endCurrentTimeline(); // end if backspace is pressed
        }
      },
    });
    blk += 1;
  }
}

// create training phase timeline element
const trainingPhase = {
  type: 'html-keyboard-response',
  timeline: trainingBlock,
  data: {
    keys: disease_keylist,
  },
};

/* *******************************************
 * *********** Create test phase *************
 ******************************************* */

// compile test phase array with all trials
for (let i = 0; i < testTrials.length; i++) {
  let stim = [];
  let phstim = [];
  let code = [];
  if (typeof testTrials[i][1] !== 'undefined') {
    const symptom1 = symptoms[testTrials[i][0].charCodeAt(0) - 65];
    const symptom2 = symptoms[testTrials[i][1].charCodeAt(0) - 65];
    stim = ['<div class="row">' +
      '<img style="height:200px;margin:20px" src="./assets/' + symptom1 +
      '.png"></img>' +
      '<img style="height:200px;margin:20px" src="./assets/' + symptom2 +
      '.png"></img></div><br><br>']
    code = [testTrials[i][0], testTrials[i][1]];
  } else {
    const symptom1 = symptoms[testTrials[i][0].charCodeAt(0) - 65];
    stim = ['<img style="height:200px;margin:20px" src="./assets/' + symptom1 + '.png"></img><br><br>'];
    code = [testTrials[i][0], ''];
  }
  testBlock.push({
    type: 'categorize-html',
    stimulus: stim,
    choices: ['q', 'p'],
    trial_duration: 10000,
    feedback_duration: 1000,
    show_stim_with_feedback: false,
    key_answer: disease_keylist,
    correct_text: '<p style="font-size:30px">Response recorded.</p>',
    incorrect_text: '<p style="font-size:30px">Response recorded.</p>',
    timeout_message: '<p style="font-size:30px">Please respond faster!</p>',
    // TODO: fix response keys
    prompt: '<p style = "font-size:30px">' +
      'What shape do you pick for this one?<br><br><p>' +
      '<p style = "font-size:30px;text-align:left">' +
      symptoms[3] + ' ' + shapeCodes[symptoms[3]] + ' : ' +
      String.fromCharCode(disease_keylist[0]) + '<br>' +
      symptoms[4] + ' ' + shapeCodes[symptoms[4]] + ' : ' +
      String.fromCharCode(disease_keylist[1]) + 
      '</p>',
    data: {
      symptom1: code[0],
      symptom2: code[1],
      stimulus: phstim,
      phase: 'test',
      trial: i + 1,
      include: true,
    },
    on_finish: function(data) {
      if (disease_keylist.indexOf(data.key_press) === 0) {
        resp = 'common';
      } else if (disease_keylist.indexOf(data.key_press) === 1) {
        resp = 'rare';
      } else {
        resp = 'none';
      };
      data.abresp = resp;
    },
  });
  testBlock.push(intertrial);
  // have a rest after each block
  if (i > 1 && (i + 1) % 24 === 0) {
    testBlock.push(testRest);
  }
}

// create test phase timeline element
const testPhase = {
  type: 'html-keyboard-response',
  timeline: testBlock,
  data: {
    keys: disease_keylist,
  },
};
