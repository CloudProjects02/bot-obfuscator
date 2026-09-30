'use strict';

function detectObfuscator(code) {
    if (!code || typeof code !== 'string') {
        return { type: 'unknown', confidence: 0, reason: 'Empty or invalid input' };
    }

    const trimmed = code.trim();

    // 1. Check Moonveil
    let mvScore = 0;
    const funcMatch = trimmed.match(/function\s+(\w+)\s*\(([\w,\s]+)\)/g);
    if (funcMatch) {
        const tableIndices = (trimmed.match(/\w+\[\d{4,5}\]/g) || []).length;
        if (tableIndices > 15) mvScore += 60;
        if (trimmed.includes('MOONVEIL') || trimmed.includes('moonveil')) mvScore += 40;
        if (trimmed.includes('__MV') || trimmed.includes('__MV_DUMP')) mvScore += 50;
        if (/(\w+)=(\w+)\[(\w+)\]/.test(trimmed) && tableIndices > 5) mvScore += 30;
    }

    // 2. Check Luraph
    let lphScore = 0;
    if (trimmed.includes('LPH_') || trimmed.includes('LURAPH') || trimmed.includes('luraph')) lphScore += 80;
    if (/LPH\|/.test(trimmed) || /LPHOBJ/.test(trimmed)) lphScore += 50;
    if (trimmed.includes('bit32.bxor') && trimmed.includes('string.byte') && /getfenv|setfenv/.test(trimmed)) lphScore += 30;
    if (/local\s+\w+=\{(\d+,?)+\}/.test(trimmed) && trimmed.includes('bit32')) lphScore += 25;

    // 3. Check Moonsec
    let msScore = 0;
    if (trimmed.includes('MoonSec') || trimmed.includes('Moonsec') || trimmed.includes('moonsec')) msScore += 90;
    if (trimmed.includes('MSV3') || trimmed.includes('MoonSec V3')) msScore += 90;
    if (/local\s+\w+=\(function\(/.test(trimmed) && trimmed.includes('string.char') && trimmed.includes('unpack')) msScore += 35;

    // 4. Check Prometheus
    let promScore = 0;
    if (trimmed.includes('Prometheus') || trimmed.includes('prometheus')) promScore += 90;
    if (trimmed.includes('PROMETHEUS_') || trimmed.includes('PromDeobf')) promScore += 80;
    if (/string\.char\(\s*\w+\s*\+\s*\d+\s*\)/.test(trimmed) && trimmed.includes('repeat') && trimmed.includes('until')) promScore += 40;

    // 5. Check Ironbrew
    let ibScore = 0;
    if (trimmed.includes('IronBrew') || trimmed.includes('Ironbrew') || trimmed.includes('IRONBREW')) ibScore += 90;
    if (trimmed.includes('IB_') || trimmed.includes('ib_')) ibScore += 60;
    if (trimmed.includes('bit.band') && trimmed.includes('bit.bxor') && trimmed.includes('loadstring')) ibScore += 35;

    // 6. Check Aspect
    let aspectScore = 0;
    if (trimmed.includes('4sp3ct') || trimmed.includes('aspect') || trimmed.includes('Aspect')) aspectScore += 80;

    // Compile ranking
    const scores = [
        { type: 'moonveil', name: 'Moonveil (Roblox VM)', score: mvScore, recommendedAction: 'moonveil' },
        { type: 'luraph', name: 'Luraph (v14-v17)', score: lphScore, recommendedAction: 'luraph' },
        { type: 'moonsec', name: 'MoonSec V2/V3', score: msScore, recommendedAction: 'moonsec' },
        { type: 'prometheus', name: 'Prometheus', score: promScore, recommendedAction: 'prometheus' },
        { type: 'ironbrew', name: 'IronBrew', score: ibScore, recommendedAction: 'ironbrew' },
        { type: 'aspect', name: 'Aspect / Lune VM', score: aspectScore, recommendedAction: 'lune' }
    ].sort((a, b) => b.score - a.score);

    const top = scores[0];
    if (top.score >= 30) {
        return {
            type: top.type,
            name: top.name,
            confidence: Math.min(100, top.score),
            recommendedAction: top.recommendedAction,
            allMatches: scores.filter(s => s.score > 0)
        };
    }

    return {
        type: 'generic_lua',
        name: 'Generic Lua / Unknown Obfuscator',
        confidence: 10,
        recommendedAction: 'moonveil',
        allMatches: scores.filter(s => s.score > 0)
    };
}

module.exports = {
    detectObfuscator
};
