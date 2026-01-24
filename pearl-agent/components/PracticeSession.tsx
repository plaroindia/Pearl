import React, { useEffect } from 'react';
import { PracticeState, PracticeSet } from '../types';
import { PRACTICE_SETS } from '../constants';

interface PracticeSessionProps {
  practiceState: PracticeState;
  onClose: () => void;
  setPracticeState: React.Dispatch<React.SetStateAction<PracticeState>>;
  showToast: (msg: string, type?: 'info' | 'success' | 'warning' | 'error') => void;
}

const PracticeSession: React.FC<PracticeSessionProps> = ({ 
  practiceState, 
  onClose, 
  setPracticeState,
  showToast
}) => {
  const currentSet = PRACTICE_SETS[practiceState.activeSetId!];
  const currentQuestion = currentSet.questions[practiceState.currentQuestionIndex];

  const handleOptionSelect = (idx: number) => {
    if (practiceState.isAnswered) return;
    setPracticeState(prev => ({ ...prev, selectedOption: idx }));
  };

  const handleHint = () => {
    if (practiceState.hints <= 0 || practiceState.isAnswered) return;
    setPracticeState(prev => ({ ...prev, hints: prev.hints - 1 }));
    showToast(`Hint: ${currentQuestion.explanation.split('.')[0]}`, 'warning');
  };

  const handleSubmit = () => {
    if (practiceState.selectedOption === null || practiceState.isAnswered) return;
    
    const isCorrect = practiceState.selectedOption === currentQuestion.correct;
    
    setPracticeState(prev => ({
      ...prev,
      isAnswered: true,
      score: isCorrect ? prev.score + 100 : prev.score,
      lives: isCorrect ? prev.lives : prev.lives - 1,
    }));

    if (!isCorrect && practiceState.lives === 1) {
      showToast('No more lives! Try the set again.', 'error');
      setTimeout(onClose, 2000);
    }
  };

  const handleNext = () => {
    if (practiceState.currentQuestionIndex < currentSet.questions.length - 1) {
      setPracticeState(prev => ({
        ...prev,
        currentQuestionIndex: prev.currentQuestionIndex + 1,
        isAnswered: false,
        selectedOption: null,
      }));
    } else {
      showToast('Practice Set Completed!', 'success');
      onClose();
    }
  };

  return (
    <div className="max-w-3xl mx-auto space-y-8 animate-slide-up">
      {/* Session Header */}
      <div className="flex items-center justify-between p-6 bg-white dark:bg-slate-950 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-xl shadow-indigo-600/5">
        <div className="flex items-center gap-4">
          <button onClick={onClose} className="p-2 bg-slate-100 dark:bg-slate-900 rounded-full hover:bg-slate-200 transition">
            <span className="material-icons">arrow_back</span>
          </button>
          <div>
            <h3 className="font-bold">{currentSet.title}</h3>
            <p className="text-xs text-slate-500">Session in progress</p>
          </div>
        </div>
        <div className="flex items-center gap-6">
          <div className="text-right">
            <p className="text-[10px] font-bold text-slate-400 uppercase">Question</p>
            <p className="font-bold">{practiceState.currentQuestionIndex + 1}/{currentSet.questions.length}</p>
          </div>
          <div className="flex items-center gap-1.5 px-3 py-1 bg-red-50 dark:bg-red-900/20 text-red-600 rounded-full font-bold">
            <span className="material-icons text-sm">favorite</span>
            <span className="text-sm">{practiceState.lives}</span>
          </div>
          <div className="text-right">
            <p className="text-[10px] font-bold text-slate-400 uppercase">Points</p>
            <p className="font-bold text-indigo-600">{practiceState.score}</p>
          </div>
        </div>
      </div>

      {/* Question Main */}
      <div className="bg-white dark:bg-slate-950 rounded-3xl border border-slate-200 dark:border-slate-800 p-8 space-y-8 shadow-2xl">
        <div className="space-y-4">
          <h2 className="text-xl md:text-2xl font-bold leading-tight">{currentQuestion.question}</h2>
          <div className="bg-slate-950 p-6 rounded-2xl border border-slate-800 font-mono text-sm">
            <pre className="text-indigo-400"><code>{currentQuestion.code}</code></pre>
          </div>
        </div>

        <div className="grid gap-3">
          {currentQuestion.options.map((opt, idx) => {
            let stateClass = 'border-slate-100 dark:border-slate-900 hover:border-indigo-300 dark:hover:border-indigo-700';
            if (practiceState.selectedOption === idx) stateClass = 'border-indigo-600 bg-indigo-50 dark:bg-indigo-900/20 ring-2 ring-indigo-500/10';
            if (practiceState.isAnswered) {
              if (idx === currentQuestion.correct) stateClass = 'border-emerald-500 bg-emerald-50 dark:bg-emerald-900/20';
              else if (practiceState.selectedOption === idx) stateClass = 'border-red-500 bg-red-50 dark:bg-red-900/20';
            }

            return (
              <button
                key={idx}
                disabled={practiceState.isAnswered}
                onClick={() => handleOptionSelect(idx)}
                className={`flex items-start gap-4 p-5 rounded-2xl border-2 transition-all text-left group ${stateClass}`}
              >
                <div className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-sm transition-colors ${
                  practiceState.selectedOption === idx ? 'bg-indigo-600 text-white' : 'bg-slate-100 dark:bg-slate-900 text-slate-400'
                }`}>
                  {String.fromCharCode(65 + idx)}
                </div>
                <span className="text-sm md:text-base font-medium leading-relaxed">{opt}</span>
                {practiceState.isAnswered && idx === currentQuestion.correct && (
                   <span className="material-icons text-emerald-500 ml-auto">check_circle</span>
                )}
                {practiceState.isAnswered && practiceState.selectedOption === idx && idx !== currentQuestion.correct && (
                   <span className="material-icons text-red-500 ml-auto">cancel</span>
                )}
              </button>
            );
          })}
        </div>

        {/* Feedback Area */}
        {practiceState.isAnswered && (
          <div className={`p-6 rounded-2xl border flex gap-4 ${
            practiceState.selectedOption === currentQuestion.correct ? 'bg-emerald-50 dark:bg-emerald-900/20 border-emerald-200 dark:border-emerald-800' : 'bg-red-50 dark:bg-red-900/20 border-red-200 dark:border-red-800'
          }`}>
             <div className={`w-10 h-10 rounded-full flex items-center justify-center text-white ${
               practiceState.selectedOption === currentQuestion.correct ? 'bg-emerald-500' : 'bg-red-500'
             }`}>
               <span className="material-icons">{practiceState.selectedOption === currentQuestion.correct ? 'emoji_events' : 'lightbulb'}</span>
             </div>
             <div>
                <h4 className="font-bold mb-1">{practiceState.selectedOption === currentQuestion.correct ? 'Great Job!' : 'Not Quite...'}</h4>
                <p className="text-sm text-slate-600 dark:text-slate-400">{currentQuestion.explanation}</p>
             </div>
          </div>
        )}

        <div className="flex items-center gap-4 pt-4">
          {!practiceState.isAnswered ? (
            <>
              <button 
                onClick={handleHint}
                disabled={practiceState.hints <= 0}
                className="px-6 py-3 bg-slate-100 dark:bg-slate-900 rounded-full font-bold text-slate-600 dark:text-slate-300 flex items-center gap-2 hover:bg-amber-100 dark:hover:bg-amber-900/30 disabled:opacity-30 transition"
              >
                <span className="material-icons text-amber-500">lightbulb</span>
                Hint ({practiceState.hints})
              </button>
              <button 
                disabled={practiceState.selectedOption === null}
                onClick={handleSubmit}
                className="flex-1 px-8 py-4 bg-indigo-600 text-white rounded-full font-bold flex items-center justify-center gap-2 shadow-xl shadow-indigo-600/20 hover:bg-indigo-700 transition disabled:opacity-50"
              >
                Check Answer
                <span className="material-icons text-sm">send</span>
              </button>
            </>
          ) : (
            <button 
              onClick={handleNext}
              className="w-full px-8 py-4 bg-slate-900 dark:bg-white text-white dark:text-slate-900 rounded-full font-bold flex items-center justify-center gap-2 transition hover:opacity-90"
            >
              {practiceState.currentQuestionIndex === currentSet.questions.length - 1 ? 'Complete Session' : 'Next Question'}
              <span className="material-icons">arrow_forward</span>
            </button>
          )}
        </div>
      </div>
    </div>
  );
};

export default PracticeSession;
