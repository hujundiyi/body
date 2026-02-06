// 弹框栈
import MBaseDialog from "@/components/dialog/MBaseDialog.vue";

let stack = [];

// 入栈操作
function push(element) {
  stack.push(element);
}


// 出栈操作
function pop() {
  return stack.pop();
}

function isEmpty() {
  return stack.length <= 0;
}

export function getBaseDialog(child) {
  let dom;
  for (let i = 0; i < child.length; i++) {
    if (child[i].$children.length > 0) {
      if ((dom = getBaseDialog(child[i].$children)) && dom && dom.$options.name === MBaseDialog.name) {
        return dom;
      }
    }
    if (child[i].$options.name === MBaseDialog.name) {
      return child[i];
    }
  }
}

function closeDialog() {
  let dialog
  if ((dialog = pop()) != null) {
    const child = getBaseDialog(dialog.$children);
    child.dialogVisible = false
    return true
  }
  return false
}

/** 按组件 name 查找并关闭弹窗，若存在则关闭并返回 true */
function closeDialogByName(componentName) {
  const idx = stack.findIndex((d) => d.$options.name === componentName);
  if (idx < 0) return false;
  const dialog = stack.splice(idx, 1)[0];
  const base = getBaseDialog(dialog.$children);
  if (base) base.dialogVisible = false;
  return true;
}

export const DialogTaskArray = {
  push, pop, closeDialog, closeDialogByName, isEmpty
}
