import React, { useState, useEffect } from 'react';
import { 
  BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, 
  AreaChart, Area
} from 'recharts';
import { authService } from '../src/services/auth.service';
import { apiService } from '../src/services/api.service';

interface WeeklyData {
  name: string;
  hours: number;
}

interface SkillGrowthData {
  month: string;
  [key: string]: string | number;
}

const Analytics: React.FC = () => {
  const [loading, setLoading] = useState(true);
  const [learningData, setLearningData] = useState<WeeklyData[]>([]);
  const [skillGrowth, setSkillGrowth] = useState<SkillGrowthData[]>([]);
  const [metrics, setMetrics] = useState({
    avgAccuracy: 0,
    retentionRate: 0,
    consistency: 0,
    masteryLevel: 'Level 1'
  });

  const authState = authService.getState();

  useEffect(() => {
    loadAnalyticsData();
  }, []);

  const loadAnalyticsData = async () => {
    try {
      setLoading(true);
      const user = authState.user;
      
      if (!user) {
        console.error('No authenticated user');
        setLoading(false);
        return;
      }

      const profileData = await apiService.getUserProfile(user.id);

      // Calculate weekly learning hours from module progress
      if (profileData?.active_sessions) {
        const weekData: WeeklyData[] = [
          { name: 'Mon', hours: 0 },
          { name: 'Tue', hours: 0 },
          { name: 'Wed', hours: 0 },
          { name: 'Thu', hours: 0 },
          { name: 'Fri', hours: 0 },
          { name: 'Sat', hours: 0 },
          { name: 'Sun', hours: 0 },
        ];

        // Distribute learning hours across the week based on activity
        profileData.active_sessions.forEach((session: any, idx: number) => {
          const dayIndex = idx % 7;
          const hours = session.actions_completed * 2; // Estimate 2 hours per action
          weekData[dayIndex].hours += hours;
        });

        setLearningData(weekData);
      }

      // Calculate skill growth over time
      if (profileData?.skills) {
        const skillsByMonth: { [key: string]: any } = {};
        const monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
        const currentMonth = new Date().getMonth();
        
        // Initialize months
        for (let i = Math.max(0, currentMonth - 3); i <= currentMonth; i++) {
          skillsByMonth[monthNames[i]] = { month: monthNames[i] };
        }

        // Group skills by month and calculate average confidence
        profileData.skills.forEach((skill: any) => {
          const skillDate = new Date(skill.created_at || skill.updated_at);
          const monthName = monthNames[skillDate.getMonth()];
          
          if (skillsByMonth[monthName]) {
            const confidencePercent = Math.round(skill.confidence_score * 100);
            skillsByMonth[monthName][skill.skill_name] = confidencePercent;
          }
        });

        const growthData = Object.values(skillsByMonth);
        setSkillGrowth(growthData);
      }

      // Calculate metrics
      if (profileData?.skills && profileData.skills.length > 0) {
        const avgConfidence = profileData.skills.reduce(
          (acc: number, skill: any) => acc + skill.confidence_score, 0
        ) / profileData.skills.length;

        const masteredSkills = profileData.skills.filter(
          (s: any) => s.confidence_score >= 0.8
        ).length;

        const level = masteredSkills >= 20 ? 'Level 5' :
                     masteredSkills >= 15 ? 'Level 4' :
                     masteredSkills >= 10 ? 'Level 3' :
                     masteredSkills >= 5 ? 'Level 2' : 'Level 1';

        setMetrics({
          avgAccuracy: Math.round(avgConfidence * 100),
          retentionRate: Math.min(100, Math.round(avgConfidence * 100 + 10)),
          consistency: profileData.profile?.streak_count 
            ? Math.min(100, profileData.profile.streak_count * 5)
            : 50,
          masteryLevel: level
        });
      }

    } catch (error) {
      console.error('Error loading analytics:', error);
      // Set default empty data
      setLearningData([
        { name: 'Mon', hours: 0 },
        { name: 'Tue', hours: 0 },
        { name: 'Wed', hours: 0 },
        { name: 'Thu', hours: 0 },
        { name: 'Fri', hours: 0 },
        { name: 'Sat', hours: 0 },
        { name: 'Sun', hours: 0 },
      ]);
    } finally {
      setLoading(false);
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center min-h-screen">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-slate-600 dark:text-slate-400">Loading analytics...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8 animate-fadeInUp pt-20 px-4 sm:px-6 lg:px-8 max-w-7xl mx-auto">
      <div className="flex justify-between items-end">
        <div>
          <h1 className="text-3xl font-extrabold">Learning Analytics</h1>
          <p className="text-slate-500">Track your progress and identify areas for improvement</p>
        </div>
        <div className="bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-xl p-1 flex shadow-sm">
          {['Week', 'Month', 'Quarter', 'All'].map(t => (
            <button 
              key={t} 
              className={`px-4 py-1.5 rounded-lg text-xs font-bold ${
                t === 'Week' 
                  ? 'bg-blue-600 text-white shadow-md' 
                  : 'text-slate-500 hover:text-blue-600'
              }`}
            >
              {t}
            </button>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Weekly Hours Chart */}
        <div className="bg-white dark:bg-slate-900 p-8 rounded-3xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-6">
          <h3 className="text-xl font-bold flex items-center gap-2">
            <span className="w-2 h-6 bg-blue-500 rounded-full"></span>
            Weekly Study Hours
          </h3>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={learningData}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
                <XAxis 
                  dataKey="name" 
                  axisLine={false} 
                  tickLine={false} 
                  tick={{fill: '#94a3b8', fontSize: 12}} 
                />
                <YAxis 
                  axisLine={false} 
                  tickLine={false} 
                  tick={{fill: '#94a3b8', fontSize: 12}} 
                />
                <Tooltip 
                  cursor={{fill: 'rgba(59, 130, 246, 0.1)'}} 
                  contentStyle={{
                    borderRadius: '12px', 
                    border: 'none', 
                    boxShadow: '0 10px 15px rgba(0,0,0,0.1)'
                  }} 
                />
                <Bar dataKey="hours" fill="#3b82f6" radius={[6, 6, 0, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Skill Growth Trend */}
        <div className="bg-white dark:bg-slate-900 p-8 rounded-3xl border border-slate-200 dark:border-slate-800 shadow-sm space-y-6">
          <h3 className="text-xl font-bold flex items-center gap-2">
            <span className="w-2 h-6 bg-purple-500 rounded-full"></span>
            Skill Growth Trend
          </h3>
          <div className="h-64">
            {skillGrowth.length > 0 ? (
              <ResponsiveContainer width="100%" height="100%">
                <AreaChart data={skillGrowth}>
                  <defs>
                    <linearGradient id="colorSkill" x1="0" y1="0" x2="0" y2="1">
                      <stop offset="5%" stopColor="#8b5cf6" stopOpacity={0.3}/>
                      <stop offset="95%" stopColor="#8b5cf6" stopOpacity={0}/>
                    </linearGradient>
                  </defs>
                  <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e2e8f0" />
                  <XAxis 
                    dataKey="month" 
                    axisLine={false} 
                    tickLine={false} 
                    tick={{fill: '#94a3b8', fontSize: 12}} 
                  />
                  <YAxis 
                    axisLine={false} 
                    tickLine={false} 
                    tick={{fill: '#94a3b8', fontSize: 12}} 
                  />
                  <Tooltip 
                    contentStyle={{
                      borderRadius: '12px', 
                      border: 'none', 
                      boxShadow: '0 10px 15px rgba(0,0,0,0.1)'
                    }}
                  />
                  <Area 
                    type="monotone" 
                    dataKey={Object.keys(skillGrowth[0] || {}).find(k => k !== 'month') || 'skill'} 
                    stroke="#8b5cf6" 
                    strokeWidth={3} 
                    fillOpacity={1} 
                    fill="url(#colorSkill)" 
                  />
                </AreaChart>
              </ResponsiveContainer>
            ) : (
              <div className="flex items-center justify-center h-full text-slate-400">
                <p>Start learning to see your skill growth</p>
              </div>
            )}
          </div>
        </div>

        {/* Metrics Grid */}
        <div className="lg:col-span-2 grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-6">
          <div className="bg-white dark:bg-slate-900 p-6 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm">
            <p className="text-sm font-bold text-slate-400 uppercase tracking-wider mb-2">Avg. Accuracy</p>
            <div className="flex items-end justify-between">
              <span className="text-3xl font-black">{metrics.avgAccuracy}%</span>
              <span className="text-xs font-bold px-2 py-1 rounded-lg bg-green-100 text-green-700">
                +5.4%
              </span>
            </div>
          </div>

          <div className="bg-white dark:bg-slate-900 p-6 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm">
            <p className="text-sm font-bold text-slate-400 uppercase tracking-wider mb-2">Retention Rate</p>
            <div className="flex items-end justify-between">
              <span className="text-3xl font-black">{metrics.retentionRate}%</span>
              <span className="text-xs font-bold px-2 py-1 rounded-lg bg-green-100 text-green-700">
                +2.1%
              </span>
            </div>
          </div>

          <div className="bg-white dark:bg-slate-900 p-6 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm">
            <p className="text-sm font-bold text-slate-400 uppercase tracking-wider mb-2">Consistency</p>
            <div className="flex items-end justify-between">
              <span className="text-3xl font-black">{metrics.consistency}%</span>
              <span className={`text-xs font-bold px-2 py-1 rounded-lg ${
                metrics.consistency >= 70 
                  ? 'bg-green-100 text-green-700' 
                  : 'bg-red-100 text-red-700'
              }`}>
                {metrics.consistency >= 70 ? '+' : '-'}
                {Math.abs(100 - metrics.consistency).toFixed(1)}%
              </span>
            </div>
          </div>

          <div className="bg-white dark:bg-slate-900 p-6 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-sm">
            <p className="text-sm font-bold text-slate-400 uppercase tracking-wider mb-2">Mastery Level</p>
            <div className="flex items-end justify-between">
              <span className="text-3xl font-black">{metrics.masteryLevel}</span>
              <span className="text-xs font-bold px-2 py-1 rounded-lg bg-green-100 text-green-700">
                New Record
              </span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Analytics;