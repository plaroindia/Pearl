
import React from 'react';
import { Section, Module } from '../types';

interface RoadmapProps {
  onOpenTaiken: (module: Module) => void;
  onNavigate: (section: Section) => void;
}

const Roadmap: React.FC<RoadmapProps> = ({ onOpenTaiken, onNavigate }) => {
  const levels = [
    {
      id: 1,
      title: 'Foundation',
      desc: 'Build strong fundamentals in web development',
      modules: [
        { id: 'web-f', title: 'Web Fundamentals', sub: 'HTML5, CSS3, Responsive Design', hours: '12h', rating: '4.9', status: 'completed', icon: '🌐' },
        { id: 'js-c', title: 'JavaScript Core', sub: 'ES6+, DOM, Async Programming', hours: '24h', rating: '4.8', status: 'completed', icon: '🟨' },
        { id: 'git-b', title: 'Git & Version Control', sub: 'Git basics, GitHub, Collaboration', hours: '8h', rating: '4.7', status: 'completed', icon: '🌿' },
      ]
    },
    {
      id: 'T',
      title: 'Taiken Story Lab',
      desc: 'Apply your foundational skills through immersive, story-based learning experiences',
      isTaiken: true,
      modules: [
        { id: 'taiken-s', title: 'Story Lab Experience', sub: 'Apply your skills in real-world scenarios', isFeatured: true, progress: 45, learners: '2.4k', status: 'active', icon: '📖' },
        { id: 'taiken-c', title: 'Community Support', sub: 'Connect with peers and get feedback', status: 'completed', icon: '🤝' },
      ]
    },
    {
      id: 2,
      title: 'Frontend Development',
      desc: 'Master modern frontend technologies and frameworks',
      modules: [
        { id: 'react-m', title: 'React Framework', sub: 'Components, Hooks, State Management', hours: '40h', status: 'locked', icon: '⚛️' },
        { id: 'state-m', title: 'State Management', sub: 'Redux, Context API, Zustand', hours: '16h', status: 'locked', icon: '📦' },
      ]
    }
  ];

  return (
    <div className="max-w-4xl mx-auto space-y-12 animate-fadeInUp">
      <div className="text-center space-y-4">
        <h1 className="text-4xl font-extrabold flex items-center justify-center gap-3">
          <span className="text-blue-600">🛣️</span> Your Learning Roadmap
        </h1>
        <p className="text-slate-500 dark:text-slate-400 max-w-2xl mx-auto">
          Interactive learning path with Taiken as a foundational step. Master one level to unlock the next.
        </p>
      </div>

      <div className="relative pl-12 sm:pl-16 border-l-4 border-slate-200 dark:border-slate-800 ml-4 sm:ml-8 space-y-16 py-8">
        {levels.map((level, lIndex) => (
          <div key={lIndex} className="relative">
            {/* Level Indicator Dot */}
            <div className={`absolute left-[-2.75rem] sm:left-[-3.25rem] top-0 w-16 h-16 rounded-full flex items-center justify-center text-2xl font-bold shadow-xl z-10 transition-transform hover:scale-110
              ${level.isTaiken ? 'taiken-gradient text-white' : 'bg-white dark:bg-slate-900 text-blue-600 border-4 border-blue-500'}`}
            >
              {level.id}
            </div>

            <div className="space-y-6">
              <div>
                <h2 className={`text-2xl font-bold ${level.isTaiken ? 'taiken-gradient bg-clip-text text-transparent' : ''}`}>
                  {level.title}
                </h2>
                <p className="text-slate-500 dark:text-slate-400">{level.desc}</p>
              </div>

              <div className="grid grid-cols-1 sm:grid-cols-2 gap-6">
                {level.modules.map((module, mIndex) => {
                  const moduleData: Module = {
                    id: module.id,
                    title: module.title,
                    description: module.sub,
                    estimatedHours: module.hours ? parseInt(module.hours.replace('h', '')) : 0,
                    status: module.status as 'completed' | 'active' | 'locked',
                    type: 'taiken',
                    skills: []
                  };

                  return (
                  <div 
                    key={mIndex} 
                    onClick={() => {
                      if (module.status !== 'locked') {
                        onOpenTaiken(moduleData);
                      }
                    }}
                    className={`p-6 rounded-2xl border transition-all duration-300 relative group
                      ${module.status === 'completed' ? 'bg-green-50/50 dark:bg-green-900/10 border-green-200 dark:border-green-800' : 
                        module.status === 'active' ? 'bg-blue-50 dark:bg-blue-900/20 border-blue-500 ring-2 ring-blue-500/20' : 
                        'bg-white dark:bg-slate-900 border-slate-200 dark:border-slate-800 opacity-60 grayscale cursor-not-allowed'}
                      ${module.isFeatured ? 'col-span-full border-2 border-purple-400' : ''}
                      ${!module.status.includes('locked') ? 'hover:shadow-xl hover:translate-y-[-4px] cursor-pointer' : ''}`}
                  >
                    {/* Status Badge */}
                    <div className="absolute top-4 right-4">
                      {module.status === 'completed' && <span className="text-green-500 bg-white dark:bg-slate-800 rounded-full p-1"><svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clipRule="evenodd"/></svg></span>}
                      {module.status === 'active' && <span className="text-blue-500 animate-spin"><svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"/></svg></span>}
                      {module.status === 'locked' && <span className="text-slate-400"><svg className="w-5 h-5" fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M5 9V7a5 5 0 0110 0v2a2 2 0 012 2v5a2 2 0 01-2 2H5a2 2 0 01-2-2v-5a2 2 0 012-2zm8-2v2H7V7a3 3 0 016 0z" clipRule="evenodd"/></svg></span>}
                    </div>

                    <div className="flex items-start gap-4">
                      <div className="w-12 h-12 bg-white dark:bg-slate-800 rounded-xl shadow-inner flex items-center justify-center text-2xl">
                        {module.icon}
                      </div>
                      <div className="flex-1 space-y-2">
                        <div>
                          <h4 className="font-bold text-lg">{module.title}</h4>
                          <p className="text-sm text-slate-500 dark:text-slate-400">{module.sub}</p>
                        </div>
                        
                        {'progress' in module && (
                          <div className="space-y-1 pt-2">
                            <div className="flex justify-between text-xs font-bold text-purple-600">
                              <span>Progress</span>
                              <span>{module.progress}%</span>
                            </div>
                            <div className="w-full bg-slate-200 dark:bg-slate-700 h-2 rounded-full overflow-hidden">
                              <div className="taiken-gradient h-full rounded-full" style={{ width: `${module.progress}%` }}></div>
                            </div>
                          </div>
                        )}

                        <div className="flex items-center gap-4 text-xs font-medium text-slate-400 pt-2">
                          {module.hours && <span>⏱️ {module.hours}</span>}
                          {module.rating && <span>⭐ {module.rating}</span>}
                          {module.learners && <span>👥 {module.learners}</span>}
                        </div>
                      </div>
                    </div>
                    
                    {module.isFeatured && (
                      <div className="mt-4 p-3 bg-purple-50 dark:bg-purple-900/10 rounded-xl border border-purple-100 dark:border-purple-800 flex items-center justify-between group-hover:bg-purple-100 transition-colors">
                        <span className="text-purple-700 dark:text-purple-300 text-sm font-bold flex items-center gap-2">
                          <svg className="w-4 h-4" fill="currentColor" viewBox="0 0 20 20"><path d="M10 18a8 8 0 100-16 8 8 0 000 16zM9.555 7.168A1 1 0 008 8v4a1 1 0 001.555.832l3-2a1 1 0 000-1.664l-3-2z"/></svg>
                          Continue: "The Startup Challenge"
                        </span>
                        <svg className="w-4 h-4 text-purple-500 transform group-hover:translate-x-1 transition-transform" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 5l7 7-7 7"/></svg>
                      </div>
                    )}
                  </div>
                  );
                })}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

export default Roadmap;
