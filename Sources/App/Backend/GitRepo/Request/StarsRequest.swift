class StarsRequest {
  let gitRepoId: Int
  let day: Date
  
  init(gitRepoId: Int, days: Double) {
    self.gitRepoId = gitRepoId
    self.day = Date(timeIntervalSinceReferenceDate: Date.timeIntervalSinceReferenceDate - Helper.convertSecondsFromAmount(days))
  }
}
