// scenes.js —— 现实合影的预置场景库（内容集，可数、可扩）。
// 每种场景 = 一种叠加画法（kind）+ 一组预置台词。台词可换成
// 语音现说的一句（存进「我的句子」跨会话复用）。
export var SCENES = [
  {
    id: 'bubble', name: '对话气泡', kind: 'bubble',
    desc: '对着一个人，头顶冒出一句台词',
    guide: '把气泡尾巴对准对方头顶上方',
    lines: ['大家好！', '生日快乐！', '干杯！', '这顿我请', '看这里，看这里', '我先干为敬']
  },
  {
    id: 'duo', name: '双人对话', kind: 'duo',
    desc: '两个人一人一句，正好接上话茬',
    guide: '左右气泡各对准一个人',
    pairs: [
      ['你听说了吗？', '什么什么？'],
      ['今天我请客', '这怎么好意思'],
      ['看镜头！', '耶——'],
      ['你又迟到了', '路上堵车……']
    ]
  },
  {
    id: 'thought', name: '心声吐槽', kind: 'thought',
    desc: '心里话用云朵气泡飘出来',
    guide: '云朵停在对方头顶偏上',
    lines: ['（其实我已经饱了）', '（假装听懂了）', '（内心毫无波动）', '（这段我能笑一年）', '（他还没发现）', '（马上到，马上到）']
  },
  {
    id: 'plate', name: '头衔名牌', kind: 'plate',
    desc: '给人头上加一块头衔牌',
    guide: '把牌子下的尖角对准头顶',
    lines: ['本日寿星', '新郎官', '新娘子', '全场 MVP', '队长', '隐藏大佬']
  },
  {
    id: 'banner', name: '庆祝横幅', kind: 'banner',
    desc: '画面上方拉开一条横幅',
    guide: '横幅在画面上方，人站在横幅下',
    lines: ['生日快乐', '恭喜发财', '新婚快乐', '毕业快乐', '欢迎欢迎', '杀青啦']
  },
  {
    id: 'frame', name: '纪念相框', kind: 'frame',
    desc: '整幅画面加相框和日期字幕',
    guide: '把人和景都收进框里',
    lines: ['美好的一天', '全家福', '旅行日记', '老友相聚', '值得纪念']
  }
];

export function sceneById(id) {
  for (var i = 0; i < SCENES.length; i++) if (SCENES[i].id === id) return SCENES[i];
  return SCENES[0];
}
