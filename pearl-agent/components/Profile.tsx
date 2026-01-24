import React, { useState, useEffect } from 'react';
import { apiService } from '../src/services/api.service';
import { authService } from '../src/services/auth.service';

interface ProfileProps {
  onNavigate?: (section: string) => void;
}

interface UserProfile {
  username: string;
  email: string;
  bio: string;
  study: string;
  location: string;
  profile_pic: string;
  role: string;
  streak_count: number;
  followers_count: number;
  following_count: number;
  created_at: string;
}

interface UserSkill {
  skill_name: string;
  confidence_score: number;
  practice_count: number;
  last_practiced_at: string;
}

interface ModuleProgress {
  skill: string;
  module_name: string;
  status: string;
  actions_completed: number;
  total_actions: number;
  started_at: string;
  completed_at: string | null;
}

const Profile: React.FC<ProfileProps> = ({ onNavigate }) => {
  const [activeTab, setActiveTab] = useState('skills');
  const [loading, setLoading] = useState(true);
  const [profile, setProfile] = useState<UserProfile | null>(null);
  const [skills, setSkills] = useState<UserSkill[]>([]);
  const [modules, setModules] = useState<ModuleProgress[]>([]);
  const [plaroPoints, setPlaroPoints] = useState(0);
  const [learningHours, setLearningHours] = useState(0);

  const authState = authService.getState();

  useEffect(() => {
    loadProfileData();
  }, []);

  const loadProfileData = async () => {
    try {
      setLoading(true);
      const user = authState.user;
      
      if (!user) {
        console.error('No authenticated user found');
        setLoading(false);
        return;
      }

      // Fetch profile data
      const profileResponse = await apiService.getUserProfile(user.id);
      
      if (profileResponse.profile) {
        setProfile(profileResponse.profile);
      }

      if (profileResponse.skills) {
        setSkills(profileResponse.skills);
      }

      // Calculate stats from available data
      if (profileResponse.active_sessions) {
        setModules(profileResponse.active_sessions);
      }

      // Calculate learning hours from module progress (estimate)
      const totalHours = modules.reduce((acc, mod) => {
        return acc + (mod.actions_completed * 2); // Estimate 2 hours per action
      }, 0);
      setLearningHours(totalHours);

      // Get Plaro points (you may need to add this endpoint)
      // For now, calculate from completed modules
      const points = modules.filter(m => m.status === 'completed').length * 50;
      setPlaroPoints(points);

    } catch (error) {
      console.error('Error loading profile:', error);
    } finally {
      setLoading(false);
    }
  };

  const stats = [
    { label: 'Learning Hours', value: learningHours.toString(), icon: '⏱️' },
    { label: 'Skills Mastered', value: skills.filter(s => s.confidence_score >= 0.8).length.toString(), icon: '🎯' },
    { label: 'Modules', value: modules.length.toString(), icon: '📖' },
    { label: 'Plaro Points', value: plaroPoints.toLocaleString(), icon: '🏆' },
  ];

  const getBadges = () => {
    const badges = [];
    
    if (skills.length >= 5) {
      badges.push({ name: 'Fast Learner', icon: '🥇', date: 'Earned', locked: false });
    }
    
    if (profile?.streak_count && profile.streak_count >= 7) {
      badges.push({ name: 'Week Warrior', icon: '🔥', date: 'Earned Today', locked: false });
    }
    
    if (modules.filter(m => m.status === 'completed').length >= 10) {
      badges.push({ name: 'Story Hunter', icon: '🎮', date: 'Earned', locked: false });
    }
    
    badges.push({ name: 'Helper', icon: '🤝', date: 'Locked', locked: true });
    
    return badges;
  };

  if (loading) {
    return (
      <div className="max-w-5xl mx-auto flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-slate-600 dark:text-slate-400">Loading profile...</p>
        </div>
      </div>
    );
  }

  if (!profile) {
    return (
      <div className="max-w-5xl mx-auto flex items-center justify-center min-h-screen">
        <div className="text-center">
          <p className="text-slate-600 dark:text-slate-400">Failed to load profile data</p>
          <button 
            onClick={loadProfileData}
            className="mt-4 px-6 py-2 bg-blue-600 text-white rounded-lg hover:bg-blue-700"
          >
            Retry
          </button>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-5xl mx-auto space-y-8 animate-fadeInUp p-6">
      <div className="bg-white dark:bg-slate-900 rounded-3xl p-8 border border-slate-200 dark:border-slate-800 shadow-xl overflow-hidden relative">
        <div className="flex flex-col md:flex-row items-center gap-8 relative z-10">
          <div className="relative">
            <img 
              src={profile.profile_pic || `https://api.dicebear.com/7.x/avataaars/svg?seed=${profile.username}`}
              className="w-32 h-32 rounded-full border-4 border-blue-500 shadow-lg"
              alt="Profile"
            />
            <button className="absolute bottom-1 right-1 bg-blue-600 text-white p-2 rounded-full hover:bg-blue-700 transition-colors shadow-md">
              <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z"/>
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M15 13a3 3 0 11-6 0 3 3 0 016 0z"/>
              </svg>
            </button>
          </div>
          <div className="flex-1 text-center md:text-left">
            <h1 className="text-3xl font-extrabold mb-1">{profile.username}</h1>
            <p className="text-blue-600 font-bold mb-4 uppercase tracking-widest text-sm">
              {profile.role || 'Learner'}
            </p>
            <p className="text-slate-500 dark:text-slate-400 max-w-lg mb-6">
              {profile.bio || 'Learning and growing every day'}
            </p>
            {profile.study && (
              <p className="text-sm text-slate-600 dark:text-slate-400 mb-2">
                📚 {profile.study}
              </p>
            )}
            {profile.location && (
              <p className="text-sm text-slate-600 dark:text-slate-400 mb-4">
                📍 {profile.location}
              </p>
            )}
            <div className="flex flex-wrap justify-center md:justify-start gap-8">
              {stats.map((s, i) => (
                <div key={i} className="text-center md:text-left">
                  <span className="block text-2xl font-black text-slate-800 dark:text-white">{s.value}</span>
                  <span className="text-xs font-bold text-slate-400 uppercase">{s.label}</span>
                </div>
              ))}
            </div>
          </div>
        </div>
        
        <div className="absolute top-[-50px] right-[-50px] w-64 h-64 bg-blue-500/5 rounded-full blur-3xl"></div>
      </div>

      <div className="flex border-b border-slate-200 dark:border-slate-800">
        {['Skills', 'Achievements', 'Progress', 'Settings'].map((tab) => (
          <button
            key={tab}
            onClick={() => setActiveTab(tab.toLowerCase())}
            className={`px-8 py-4 text-sm font-bold transition-all relative ${
              activeTab === tab.toLowerCase() 
                ? 'text-blue-600' 
                : 'text-slate-400 hover:text-slate-600 dark:hover:text-slate-300'
            }`}
          >
            {tab}
            {activeTab === tab.toLowerCase() && (
              <div className="absolute bottom-0 left-0 right-0 h-1 bg-blue-600 rounded-t-full"></div>
            )}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">
        <div className="lg:col-span-2 space-y-6">
          {activeTab === 'skills' && (
            <div className="bg-white dark:bg-slate-900 rounded-2xl p-6 border border-slate-200 dark:border-slate-800 space-y-6">
              <h3 className="text-xl font-bold">Skills Inventory</h3>
              {skills.length > 0 ? (
                <div className="space-y-6">
                  {skills.map((skill, i) => (
                    <div key={i} className="space-y-2">
                      <div className="flex justify-between items-center text-sm">
                        <span className="font-bold">{skill.skill_name}</span>
                        <span className="font-bold text-blue-600">
                          {Math.round(skill.confidence_score * 100)}%
                        </span>
                      </div>
                      <div className="h-2 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                        <div 
                          className="h-full bg-blue-500 rounded-full transition-all duration-500" 
                          style={{ width: `${skill.confidence_score * 100}%` }}
                        ></div>
                      </div>
                      <p className="text-xs text-slate-500">
                        Practiced {skill.practice_count} times
                        {skill.last_practiced_at && ` • Last: ${new Date(skill.last_practiced_at).toLocaleDateString()}`}
                      </p>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-slate-500 text-center py-8">
                  No skills tracked yet. Start learning to build your skill inventory!
                </p>
              )}
            </div>
          )}
          
          {activeTab === 'achievements' && (
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-6">
              {getBadges().map((badge, i) => (
                <div 
                  key={i} 
                  className={`p-6 rounded-2xl border text-center transition-all ${
                    badge.locked 
                      ? 'bg-slate-50 dark:bg-slate-900/50 border-slate-200 grayscale' 
                      : 'bg-white dark:bg-slate-900 border-blue-100 shadow-sm'
                  }`}
                >
                  <div className="text-4xl mb-4">{badge.icon}</div>
                  <h4 className="font-bold text-sm mb-1">{badge.name}</h4>
                  <p className="text-[10px] text-slate-400 uppercase font-black">{badge.date}</p>
                </div>
              ))}
            </div>
          )}

          {activeTab === 'progress' && (
            <div className="bg-white dark:bg-slate-900 rounded-2xl p-6 border border-slate-200 dark:border-slate-800 space-y-4">
              <h3 className="text-xl font-bold">Learning Progress</h3>
              {modules.length > 0 ? (
                <div className="space-y-4">
                  {modules.map((module, i) => (
                    <div key={i} className="p-4 bg-slate-50 dark:bg-slate-800 rounded-xl">
                      <div className="flex justify-between items-start mb-2">
                        <div>
                          <h4 className="font-bold text-sm">{module.module_name || `Module ${i + 1}`}</h4>
                          <p className="text-xs text-slate-500">{module.skill}</p>
                        </div>
                        <span className={`text-xs px-2 py-1 rounded-full font-bold ${
                          module.status === 'completed' ? 'bg-green-100 text-green-700' :
                          module.status === 'active' ? 'bg-blue-100 text-blue-700' :
                          'bg-slate-200 text-slate-600'
                        }`}>
                          {module.status}
                        </span>
                      </div>
                      <div className="flex items-center gap-2 text-xs text-slate-600">
                        <div className="flex-1 bg-slate-200 dark:bg-slate-700 rounded-full h-2">
                          <div 
                            className="bg-blue-500 h-2 rounded-full transition-all"
                            style={{ width: `${(module.actions_completed / module.total_actions) * 100}%` }}
                          ></div>
                        </div>
                        <span>{module.actions_completed}/{module.total_actions}</span>
                      </div>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-slate-500 text-center py-8">
                  No active modules yet. Start a learning path to see your progress!
                </p>
              )}
            </div>
          )}

          {activeTab === 'settings' && (
            <div className="bg-white dark:bg-slate-900 rounded-2xl p-6 border border-slate-200 dark:border-slate-800 space-y-4">
              <h3 className="text-xl font-bold">Profile Settings</h3>
              <div className="space-y-4">
                <div>
                  <label className="block text-sm font-bold mb-2">Email</label>
                  <input 
                    type="email" 
                    value={profile.email || ''} 
                    disabled
                    className="w-full px-4 py-2 rounded-lg border border-slate-200 dark:border-slate-700 bg-slate-50 dark:bg-slate-800"
                  />
                </div>
                <div>
                  <label className="block text-sm font-bold mb-2">Bio</label>
                  <textarea 
                    value={profile.bio || ''} 
                    rows={3}
                    className="w-full px-4 py-2 rounded-lg border border-slate-200 dark:border-slate-700 dark:bg-slate-800"
                    placeholder="Tell us about yourself..."
                  />
                </div>
                <button className="w-full bg-blue-600 text-white py-3 rounded-xl font-bold hover:bg-blue-700 transition-all">
                  Save Changes
                </button>
              </div>
            </div>
          )}
        </div>

        <div className="space-y-6">
          <div className="bg-gradient-to-br from-indigo-600 to-purple-700 rounded-2xl p-6 text-white shadow-lg">
            <h3 className="text-lg font-bold mb-4">Resume Builder</h3>
            <p className="text-indigo-100 text-sm mb-6 opacity-90 leading-relaxed">
              Generate a professional, verified resume based on your mastered skills and learning progress.
            </p>
            <button className="w-full bg-white text-indigo-700 py-3 rounded-xl font-bold hover:bg-indigo-50 transition-all flex items-center justify-center gap-2">
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"/>
              </svg>
              Build Resume
            </button>
          </div>

          <div className="bg-white dark:bg-slate-900 rounded-2xl p-6 border border-slate-200 dark:border-slate-800">
            <h3 className="text-lg font-bold mb-4">Account Stats</h3>
            <div className="space-y-3">
              <div className="flex justify-between items-center">
                <span className="text-sm text-slate-600 dark:text-slate-400">Streak</span>
                <span className="font-bold">{profile.streak_count} days 🔥</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-slate-600 dark:text-slate-400">Followers</span>
                <span className="font-bold">{profile.followers_count}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-slate-600 dark:text-slate-400">Following</span>
                <span className="font-bold">{profile.following_count}</span>
              </div>
              <div className="flex justify-between items-center">
                <span className="text-sm text-slate-600 dark:text-slate-400">Member Since</span>
                <span className="font-bold text-xs">
                  {new Date(profile.created_at).toLocaleDateString()}
                </span>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Profile;