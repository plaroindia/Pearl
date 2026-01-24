
import React, { useState } from 'react';

interface OnboardingProps {
  onComplete: () => void;
}

const Onboarding: React.FC<OnboardingProps> = ({ onComplete }) => {
  const [step, setStep] = useState(1);
  const [formData, setFormData] = useState({
    status: '',
    field: '',
    careerGoal: '',
    targetRole: '',
    timeCommitment: '5-10 hours/week',
  });

  const nextStep = () => setStep(prev => Math.min(prev + 1, 3));
  const prevStep = () => setStep(prev => Math.max(prev - 1, 1));

  const handleFinish = () => {
    localStorage.setItem('onboarded', 'true');
    onComplete();
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-4 sm:p-8 animate-fadeInUp">
      <div className="max-w-2xl w-full bg-white dark:bg-slate-900 rounded-[2.5rem] shadow-2xl border border-slate-200 dark:border-slate-800 overflow-hidden flex flex-col sm:flex-row">
        {/* Sidebar */}
        <div className="sm:w-64 bg-blue-600 p-8 sm:p-12 text-white flex flex-col justify-between">
          <div>
            <div className="w-10 h-10 bg-white/20 rounded-xl mb-12 flex items-center justify-center font-black italic">P</div>
            <div className="space-y-8">
              {[1, 2, 3].map((num) => (
                <div key={num} className="flex items-center gap-4">
                  <div className={`w-8 h-8 rounded-full flex items-center justify-center text-sm font-black transition-all ${step === num ? 'bg-white text-blue-600 scale-125' : 'bg-white/20 text-white/50'}`}>
                    {num}
                  </div>
                  <span className={`text-sm font-bold transition-all ${step === num ? 'opacity-100' : 'opacity-40'}`}>
                    {num === 1 ? 'Basic Info' : num === 2 ? 'Goals' : 'Preferences'}
                  </span>
                </div>
              ))}
            </div>
          </div>
          <div className="hidden sm:block mt-20">
            <p className="text-xs text-blue-200 leading-relaxed font-medium">
              Join thousands of learners achieving their career dreams with PEARL.
            </p>
          </div>
        </div>

        {/* Content */}
        <div className="flex-1 p-8 sm:p-12 flex flex-col justify-center">
          {step === 1 && (
            <div className="space-y-8">
              <div>
                <h2 className="text-3xl font-black mb-2">Basic Information</h2>
                <p className="text-slate-500 text-sm">Help us understand your current professional standing.</p>
              </div>
              <div className="space-y-6">
                <div className="space-y-2">
                  <label className="text-sm font-bold text-slate-700 dark:text-slate-300">Your Current Status</label>
                  <select 
                    className="w-full bg-slate-50 dark:bg-slate-800 border-2 border-slate-100 dark:border-slate-700 p-4 rounded-xl focus:border-blue-500 focus:outline-none font-medium"
                    value={formData.status}
                    onChange={(e) => setFormData({...formData, status: e.target.value})}
                  >
                    <option value="">Select Status...</option>
                    <option value="student">Student</option>
                    <option value="employed">Employed</option>
                    <option value="freelance">Freelance</option>
                    <option value="career-changer">Career Changer</option>
                  </select>
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-bold text-slate-700 dark:text-slate-300">Field of Interest</label>
                  <input 
                    type="text" 
                    placeholder="e.g. Software Engineering"
                    className="w-full bg-slate-50 dark:bg-slate-800 border-2 border-slate-100 dark:border-slate-700 p-4 rounded-xl focus:border-blue-500 focus:outline-none font-medium"
                    value={formData.field}
                    onChange={(e) => setFormData({...formData, field: e.target.value})}
                  />
                </div>
              </div>
            </div>
          )}

          {step === 2 && (
            <div className="space-y-8">
              <div>
                <h2 className="text-3xl font-black mb-2">Define Your Goal</h2>
                <p className="text-slate-500 text-sm">What do you want to achieve with PEARL?</p>
              </div>
              <div className="space-y-6">
                <div className="space-y-2">
                  <label className="text-sm font-bold text-slate-700 dark:text-slate-300">Primary Career Goal</label>
                  <input 
                    type="text" 
                    placeholder="e.g. Become a Senior Frontend dev"
                    className="w-full bg-slate-50 dark:bg-slate-800 border-2 border-slate-100 dark:border-slate-700 p-4 rounded-xl focus:border-blue-500 focus:outline-none font-medium"
                    value={formData.careerGoal}
                    onChange={(e) => setFormData({...formData, careerGoal: e.target.value})}
                  />
                </div>
                <div className="space-y-2">
                  <label className="text-sm font-bold text-slate-700 dark:text-slate-300">Target Role</label>
                  <input 
                    type="text" 
                    placeholder="e.g. Tech Lead at Google"
                    className="w-full bg-slate-50 dark:bg-slate-800 border-2 border-slate-100 dark:border-slate-700 p-4 rounded-xl focus:border-blue-500 focus:outline-none font-medium"
                    value={formData.targetRole}
                    onChange={(e) => setFormData({...formData, targetRole: e.target.value})}
                  />
                </div>
              </div>
            </div>
          )}

          {step === 3 && (
            <div className="space-y-8">
              <div>
                <h2 className="text-3xl font-black mb-2">Learning Style</h2>
                <p className="text-slate-500 text-sm">Tailor your mentor experience.</p>
              </div>
              <div className="space-y-6">
                <div className="space-y-2">
                  <label className="text-sm font-bold text-slate-700 dark:text-slate-300">Time Commitment</label>
                  <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                    {['1-5h/week', '5-10h/week', '10-20h/week', '20+h/week'].map((time) => (
                      <button 
                        key={time}
                        onClick={() => setFormData({...formData, timeCommitment: time})}
                        className={`p-4 rounded-xl border-2 font-bold transition-all ${formData.timeCommitment === time ? 'bg-blue-600 text-white border-blue-600 shadow-lg scale-105' : 'bg-slate-50 dark:bg-slate-800 border-slate-100 dark:border-slate-700 text-slate-500 hover:border-blue-200'}`}
                      >
                        {time}
                      </button>
                    ))}
                  </div>
                </div>
              </div>
            </div>
          )}

          <div className="mt-12 flex justify-between gap-4">
            <button 
              onClick={prevStep}
              className={`px-8 py-4 rounded-xl font-bold transition-all ${step === 1 ? 'opacity-0 pointer-events-none' : 'text-slate-400 hover:text-slate-600 hover:bg-slate-100 dark:hover:bg-slate-800'}`}
            >
              Back
            </button>
            <button 
              onClick={step === 3 ? handleFinish : nextStep}
              className="bg-blue-600 text-white px-10 py-4 rounded-xl font-bold hover:bg-blue-700 transition-all shadow-xl hover:translate-y-[-2px] active:translate-y-[0px]"
            >
              {step === 3 ? 'Finish Setting Up 🚀' : 'Next Step'}
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Onboarding;
