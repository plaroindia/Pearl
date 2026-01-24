import React, { useState, useEffect } from 'react';
import { GameState } from '../types';
import { STORY_QUESTIONS } from '../constants';

interface StoryViewProps {
  gameState: GameState;
  onStorySubmit: (selected: number) => void;
  onHintClick: () => void;
}

const StoryView: React.FC<StoryViewProps> = ({ gameState, onStorySubmit, onHintClick }) => {
  const episodeKey = `episode${gameState.currentEpisode}`;
  const episodeQuestions = STORY_QUESTIONS[episodeKey] || STORY_QUESTIONS['episode1'];
  const currentQuestion = episodeQuestions[gameState.currentQuestion - 1] || episodeQuestions[0];
  const [selectedOption, setSelectedOption] = useState<number | null>(null);

  useEffect(() => {
    setSelectedOption(null);
  }, [gameState.currentQuestion, gameState.currentEpisode]);

  const handleSubmit = () => {
    if (selectedOption !== null) {
      onStorySubmit(selectedOption);
    }
  };

  return (
    <div className="space-y-8">
      {/* Visual Dialogue Scene */}
      <div className="bg-white dark:bg-slate-950 rounded-3xl border border-slate-200 dark:border-slate-800 overflow-hidden shadow-xl shadow-slate-200/50 dark:shadow-none">
        <div className="bg-slate-50 dark:bg-slate-900/50 p-4 border-bottom border-slate-200 dark:border-slate-800 flex items-center justify-between">
          <div className="flex items-center gap-2 text-slate-600 dark:text-slate-400 font-bold text-sm">
            <span className="material-icons text-indigo-500">auto_stories</span>
            Story Scene
          </div>
          <div className="bg-indigo-600 px-3 py-1 rounded-full text-white text-[10px] font-bold">
            Question {gameState.currentQuestion}/3
          </div>
        </div>
        
        <div className="p-6 md:p-8 space-y-8">
          {/* Mentor Message */}
          <div className="flex gap-4 group">
            <div className="w-12 h-12 rounded-full overflow-hidden border-2 border-indigo-600 flex-shrink-0 transition-transform group-hover:scale-110">
              <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Maya" alt="Mentor" />
            </div>
            <div className="flex-1 space-y-2">
              <div className="flex items-center justify-between">
                <span className="font-bold text-slate-900 dark:text-white">Maya <span className="text-xs text-slate-500 ml-2">Senior Developer</span></span>
                <span className="text-[10px] text-slate-400">10:30 AM</span>
              </div>
              <div className="bg-slate-100 dark:bg-slate-900 p-4 rounded-2xl rounded-tl-none border border-slate-200 dark:border-slate-800">
                <p className="text-sm leading-relaxed mb-4">
                  "Alex, we've got an issue here. This logic isn't holding up under pressure. Take a look at this snippet:"
                </p>
                <div className="bg-slate-950 p-4 rounded-xl overflow-x-auto border border-slate-800">
                  <pre className="text-xs text-indigo-300 font-mono"><code>{currentQuestion.code}</code></pre>
                </div>
                <p className="text-sm mt-4 italic font-medium">"What's the best way to handle this correctly?"</p>
              </div>
            </div>
          </div>

          {/* User Message */}
          <div className="flex flex-row-reverse gap-4 group">
            <div className="w-12 h-12 rounded-full overflow-hidden border-2 border-indigo-500 flex-shrink-0 transition-transform group-hover:scale-110">
              <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Alex" alt="You" />
            </div>
            <div className="flex-1 space-y-2 text-right">
              <div className="flex items-center justify-between flex-row-reverse">
                <span className="font-bold text-slate-900 dark:text-white">You <span className="text-xs text-slate-500 mr-2 font-normal">Junior Developer</span></span>
                <span className="text-[10px] text-slate-400">10:32 AM</span>
              </div>
              <div className="bg-indigo-600 p-4 rounded-2xl rounded-tr-none text-white ml-auto max-w-sm inline-block shadow-lg shadow-indigo-600/20">
                <p className="text-sm leading-relaxed">Let me analyze the code and find the best solution...</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Question Card */}
      <div className="bg-white dark:bg-slate-950 rounded-3xl border border-slate-200 dark:border-slate-800 p-6 md:p-8 space-y-6 shadow-xl shadow-slate-200/50 dark:shadow-none">
        <div>
          <h2 className="text-2xl font-bold mb-2">{currentQuestion.question}</h2>
          <p className="text-slate-500 text-sm">Select the most accurate answer based on production coding standards.</p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {currentQuestion.options.map((option, idx) => (
            <button
              key={idx}
              onClick={() => setSelectedOption(idx)}
              className={`p-4 rounded-2xl border-2 text-left transition-all relative overflow-hidden group ${
                selectedOption === idx 
                  ? 'bg-indigo-50 dark:bg-indigo-900/20 border-indigo-600' 
                  : 'bg-white dark:bg-slate-950 border-slate-100 dark:border-slate-900 hover:border-indigo-300 dark:hover:border-indigo-700'
              }`}
            >
              <div className="flex items-start gap-4">
                <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm transition-colors ${
                  selectedOption === idx ? 'bg-indigo-600 text-white' : 'bg-slate-100 dark:bg-slate-900 text-slate-400'
                }`}>
                  {String.fromCharCode(65 + idx)}
                </div>
                <div className="flex-1">
                  <p className="text-sm font-medium leading-relaxed">{option}</p>
                </div>
              </div>
            </button>
          ))}
        </div>

        <div className="flex items-center justify-between gap-4 pt-4">
          <button 
            onClick={onHintClick}
            className="px-6 py-2 bg-slate-100 dark:bg-slate-900 text-slate-600 dark:text-slate-300 rounded-full text-sm font-bold flex items-center gap-2 hover:bg-amber-100 dark:hover:bg-amber-900/30 transition-colors"
          >
            <span className="material-icons text-amber-500">lightbulb</span>
            Get Hint
          </button>
          <button 
            disabled={selectedOption === null}
            onClick={handleSubmit}
            className="flex-1 md:flex-none px-8 py-3 bg-indigo-600 disabled:opacity-50 disabled:cursor-not-allowed text-white rounded-full font-bold flex items-center justify-center gap-2 shadow-lg shadow-indigo-600/20 hover:bg-indigo-700 transition"
          >
            Submit Answer
            <span className="material-icons text-sm">send</span>
          </button>
        </div>
      </div>
    </div>
  );
};

export default StoryView;
