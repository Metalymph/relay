///|
#cfg(target="native")
fn main {
  println("Relay Message Queue Demo (Native)")
  println("---------------------------------")
  println("The demo logic is currently disabled in the main package to ensure")
  println("compatibility during the multi-target 'moon publish' process.")
  println("Please use 'moon test' to verify full functionality.")
}

///|
#cfg(not(target="native"))
fn main {
  println("Relay Demo: Native target only.")
}
