local protocol = wf.executeScript("F/getProtocol")()
assert(protocol, "Unsupported protocol!")
return protocol
