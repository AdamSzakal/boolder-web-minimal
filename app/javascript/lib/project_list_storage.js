const STORAGE_KEY = "projectList.v1"
const DEFAULT_LIST = { name: null, problemIds: [] }

export function loadProjectList() {
  try {
    return JSON.parse(localStorage.getItem(STORAGE_KEY)) || DEFAULT_LIST
  } catch {
    return DEFAULT_LIST
  }
}

export function saveProjectList(list) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(list))
}

export function addProblem(problemId) {
  const list = loadProjectList()
  list.problemIds = Array.from(new Set([...list.problemIds, problemId]))
  saveProjectList(list)
  return list
}

export function removeProblem(problemId) {
  const list = loadProjectList()
  list.problemIds = list.problemIds.filter(id => id !== problemId)
  saveProjectList(list)
  return list
}

export function hasProblem(problemId) {
  const list = loadProjectList()
  return list.problemIds.includes(problemId)
}
