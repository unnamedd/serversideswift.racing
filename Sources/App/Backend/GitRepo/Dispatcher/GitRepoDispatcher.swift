import Vapor

class GitRepoDispatcher {
  let gitRepoRepository = GitRepoRepository()
  let starsRepo = StarsRepository()
  let drop: Droplet
  
  init(drop: Droplet) {
    self.drop = drop
  }

  ///
  /// NEW
  ///
  
  func getAll(req: GitRepoListRequest) throws -> GitRepoListResponse? {
    guard let list = try gitRepoRepository.findAllGitRepos() else {
      throw RepositoryError.couldNotFetchGitRepos("could not fetch git repositories")
    }
    return GitRepoListResponse(list: list)
  }
  
  func getStars(req: StarsRequest) throws -> StarsResponse? {
    guard let list = try gitRepoRepository.findStarsSince(date: req.day, of: req.gitRepoId) else {
      throw GitRepoError.couldNotGetStars("could not find stars since '\(req.day)' for '\(req.gitRepoId)'")
    }
    return StarsResponse(gitRepoId: req.gitRepoId, list: list)
  }
  
  ///
  /// OLD
  ///
  
  // MARK: public functions
  
  func fetchStars() throws {
    try fetchStarsOf(scraper: VaporScraper(drop: drop))
    try fetchStarsOf(scraper: PerfectScraper(drop: drop))
    try fetchStarsOf(scraper: KituraScraper(drop: drop))
    try fetchStarsOf(scraper: ZewoScraper(drop: drop))
  }
  
  func getStarsPerDay(of repoId: Int) throws -> Int {
    let stars = try starsRepo.findAllStarsBy(repoId: repoId).map {star in star.amount}
    return Int(stars.reduce(0, +) / stars.count)
  }
  
  func getStarsOfLastThirtyDays(of repoId: Int) throws -> [Stars] {
    let todayMinusThirtyDays = Date(timeIntervalSinceReferenceDate: Date.timeIntervalSinceReferenceDate-Days.thirty.rawValue)
    return try starsRepo.findAllStarsSince(date: todayMinusThirtyDays, of: repoId)
  }
  
  func getAllStarsBy(repoId: Int) throws -> [Stars] {
    return try starsRepo.findAllStarsBy(repoId: repoId)
  }
  
  // MARK: private functions
  
  private func fetchStarsOf(scraper: Scraper) throws {
    let starsAmount = try scraper.scrapeStars()
    
    guard let repo = try GitRepo.makeQuery().filter("name", scraper.name).first() else {
      try createRepository(scraper: scraper)
      try fetchStarsOf(scraper: scraper)
      return
    }
    
    guard let repoId = repo.id?.int else {
      throw RepositoryError.noRepositoryIdIsSet("cannot get current repo id as int")
    }
    
    let stars = Stars(repositoryId: repoId, amount: starsAmount)
    try stars.save()
  }
  
  private func createRepository(scraper: Scraper) throws {
    let vaporRepo = GitRepo(name: scraper.name, url: scraper.url, website: scraper.website)
    try vaporRepo.save()
  }
}
