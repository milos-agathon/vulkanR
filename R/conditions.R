.vkr_stop <- function(msg, cls) {
  err <- simpleError(msg)
  class(err) <- c(cls, "vulkanr_error", class(err))
  stop(err)
}

.handle_extendr_err <- function(e) {
  msg <- conditionMessage(e)
  cls <- if (grepl("DeviceInit", msg))       "vkr_device"
   else if (grepl("ShaderCompilation", msg)) "vkr_shader"
   else if (grepl("OutOfMemory", msg))       "vkr_oom"
   else if (grepl("InvalidInput", msg))      "vkr_input"
   else if (grepl("Capability", msg))        "vkr_caps"
   else if (grepl("Io", msg))                 "vkr_io"
   else                                       "vulkanr_error"
  .vkr_stop(msg, cls)
}
