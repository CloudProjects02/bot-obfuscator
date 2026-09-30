const { parseLua } = require('../lua/parse');
const src = `local B = nil
if (B and (_call3 >= D)) or ((not B) and (_call3 <= D)) then
    print('dead')
else
    print('alive')
end`;
const ast = parseLua(src);
const ifstmt = ast.body.find(s => s.type === 'IfStatement');
const cond = ifstmt.clauses[0].condition;
console.log('cond type:', cond.type, 'oper:', cond.operator);
if (cond.type === 'BinaryExpression' && cond.operator === 'or') {
  let left = cond.left;
  let right = cond.right;
  while (left.type === 'ParenthesisExpression') left = left.expression;
  while (right.type === 'ParenthesisExpression') right = right.expression;
  console.log('left type:', left.type, 'oper:', left.operator);
  console.log('right type:', right.type, 'oper:', right.operator);
  if (left.type === 'BinaryExpression' && left.operator === 'and' &&
      right.type === 'BinaryExpression' && right.operator === 'and') {
    let lc = left.left;
    let rc = right.left;
    while (lc.type === 'ParenthesisExpression') lc = lc.expression;
    while (rc.type === 'ParenthesisExpression') rc = rc.expression;
    console.log('leftCond type:', lc.type, 'name:', lc.name);
    console.log('rightCond type:', rc.type, 'oper:', rc.operator);
  }
}