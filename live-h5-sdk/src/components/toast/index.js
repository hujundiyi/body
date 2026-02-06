import Vue from "vue";
import MToast from "@/components/toast/MToast.vue";

function createToast(props) {
  const Instance = new Vue({
    render: h => h(MToast, {props})
  })
  Instance.$mount()
  return Instance.$children[0]
}

export function toast(msg, type = 'info', duration = 2000) {
  const toast = createToast({
    message: msg,
    type,
    duration
  })
  toast.$on('close', () => {
    document.body.removeChild(toast.$el)
    toast.$destroy()
  })
}

export function toastWarning(msg) {
  return toast(msg, 'warning')
}
