import { Question, PracticeSet } from './types';

export const STORY_QUESTIONS: Record<string, Question[]> = {
  episode1: [
    {
      id: 1,
      question: "What's the main bug in this authentication function?",
      code: `function authenticateUser(users) {
    let total = 0;
    for (let i = 0; i < users.length; i++) {
        total += users[i].score;
    }
    return total;
}`,
      options: [
        "The function is not exported",
        "Missing error handling for undefined users",
        "The loop should use forEach instead",
        "Missing return type declaration"
      ],
      correct: 1,
      explanation: "If users is undefined or null, users.length will throw a TypeError. Professional code should always validate inputs."
    },
    {
      id: 2,
      question: "How would you fix this bug?",
      code: `function authenticateUser(users) {
    // Fix goes here
    let total = 0;
    for (let i = 0; i < users.length; i++) {
        total += users[i].score;
    }
    return total;
}`,
      options: [
        "Add: if (!users) return 0;",
        "Add: users = users || [];",
        "Add: try { ... } catch(e) { return 0; }",
        "All of the above"
      ],
      correct: 3,
      explanation: "All three approaches would prevent the TypeError in different ways, though input validation is usually cleanest."
    },
    {
      id: 3,
      question: "What's the best practice for this scenario?",
      code: `function processData(data) {
    // Process data here
}`,
      options: [
        "Always validate input parameters",
        "Use TypeScript for type safety",
        "Add comprehensive error handling",
        "All of the above"
      ],
      correct: 3,
      explanation: "Professional code should include all these practices for robustness and maintainability."
    }
  ],
  episode2: [
    {
      id: 1,
      question: "What's missing in the getUserData function?",
      code: `async function getUserData(id) {
    const response = fetch(\`/api/users/\${id}\`);
    const data = response.json();
    return data;
}`,
      options: [
        "Missing error handling for network failures",
        "Missing await before fetch and response.json()",
        "Missing input validation for the ID parameter",
        "Missing Content-Type header"
      ],
      correct: 1,
      explanation: "Both fetch() and response.json() return Promises that need to be awaited. Without await, you're working with Promise objects."
    },
    {
      id: 2,
      question: "How should this function handle errors?",
      code: `async function getUserData(id) {
    // Error handling should be added here
}`,
      options: [
        "Wrap everything in try-catch",
        "Check response.ok status",
        "Add timeout handling",
        "All of the above"
      ],
      correct: 3,
      explanation: "Robust API calls should include all these error handling strategies to ensure a good UX."
    },
    {
      id: 3,
      question: "What's the benefit of using async/await?",
      code: `// Using async/await vs .then()`,
      options: [
        "Cleaner, more readable code",
        "Better error handling with try-catch",
        "Easier debugging",
        "All of the above"
      ],
      correct: 3,
      explanation: "Async/await provides all these benefits over traditional Promise chains, leading to linear flow."
    }
  ],
  episode3: [
    {
      id: 1,
      question: "What's wrong with this production code?",
      code: `function calculateTotal(items) {
    let total = 0;
    items.forEach(item => {
        total += item.price * item.quantity;
    });
    return total.toFixed(2);
}`,
      options: [
        "No validation for items parameter",
        "toFixed() returns a string, not a number",
        "Missing error handling for NaN values",
        "All of the above"
      ],
      correct: 3,
      explanation: "Production code should handle all edge cases and return proper types. Mixed types can lead to bugs."
    },
    {
      id: 2,
      question: "How would you optimize this for performance?",
      code: `function processLargeArray(arr) {
    return arr
        .filter(x => x > 0)
        .map(x => x * 2)
        .reduce((sum, x) => sum + x, 0);
}`,
      options: [
        "Use a single for loop instead",
        "Implement pagination for large arrays",
        "Use Web Workers for parallel processing",
        "All of the above"
      ],
      correct: 3,
      explanation: "For very large arrays, reducing iteration count or using background threads is essential."
    },
    {
      id: 3,
      question: "What's missing for production readiness?",
      code: `function criticalFunction(data) {
    // Critical business logic here
    return result;
}`,
      options: [
        "Comprehensive logging",
        "Input validation and sanitization",
        "Unit tests and error boundaries",
        "All of the above"
      ],
      correct: 3,
      explanation: "Production code requires all these elements for reliability, monitoring, and future maintenance."
    }
  ]
};

export const PRACTICE_SETS: Record<string, PracticeSet> = {
  'error-handling': {
    title: 'Error Handling',
    description: 'Master try-catch, promises, and debugging techniques',
    icon: 'bug_report',
    color: '#ef4444',
    questions: [
      {
        id: 1,
        question: "What will be the output of this code?",
        code: `try {
    throw new Error('Something went wrong');
} catch (error) {
    console.log('Caught:', error.message);
}
console.log('After try-catch');`,
        options: [
          "Caught: Something went wrong\nAfter try-catch",
          "Error: Something went wrong",
          "Nothing will be printed",
          "Uncaught Error: Something went wrong"
        ],
        correct: 0,
        explanation: "The error is caught and handled, then execution continues after the try-catch block."
      },
      {
        id: 2,
        question: "Which of these correctly handles a Promise rejection?",
        code: `fetch('/api/data')
    .then(response => response.json())`,
        options: [
          ".then(data => console.log(data), error => console.error(error))",
          ".catch(error => console.error(error))",
          "Both A and B",
          "None of the above"
        ],
        correct: 2,
        explanation: "Both .then() with two arguments and .catch() can handle Promise rejections."
      }
    ]
  },
  'debugging': {
    title: 'Debugging',
    description: 'Master browser DevTools and debugging methods',
    icon: 'search',
    color: '#3b82f6',
    questions: [
      {
        id: 1,
        question: "What does console.trace() do?",
        code: `function a() { b(); }
function b() { c(); }
function c() { console.trace(); }
a();`,
        options: [
          "Shows the call stack at the point where it's called",
          "Measures execution time",
          "Groups console messages",
          "Clears the console"
        ],
        correct: 0,
        explanation: "console.trace() outputs a full stack trace to the console, showing how you got to that function."
      }
    ]
  },
  'api-integration': {
    title: 'API Integration',
    description: 'Learn REST APIs, fetch, and authentication',
    icon: 'api',
    color: '#10b981',
    questions: [
      {
        id: 1,
        question: "What's missing in this fetch request?",
        code: `fetch('/api/login', {
    method: 'POST',
    body: JSON.stringify({ user: 'test' })
});`,
        options: [
          "Content-Type header",
          "Error handling",
          "Both A and B",
          "Nothing is missing"
        ],
        correct: 2,
        explanation: "Always set Content-Type: application/json for JSON payloads and handle potential errors."
      }
    ]
  }
};
