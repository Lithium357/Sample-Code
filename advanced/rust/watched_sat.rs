//! DPLL SAT solver with two watched literals and reversible assignment trails.
//! rustc --edition=2021 watched_sat.rs -o sat && ./sat
//! No clause learning: exponential worst case. Bounded educational instances.
//! CNF literals are signed one-based variable numbers; 0 is invalid.
#[derive(Clone)]
struct Clause {
    literals: Vec<i32>,
    watched: [usize; 2],
}
struct Solver {
    clauses: Vec<Clause>,
    watchers: Vec<Vec<usize>>,
    assignment: Vec<i8>,
    trail: Vec<i32>,
    head: usize,
    inconsistent: bool,
}
fn index(literal: i32) -> usize {
    2 * (literal.unsigned_abs() as usize - 1) + usize::from(literal < 0)
}
impl Solver {
    fn new(variables: usize, input: &[Vec<i32>]) -> Result<Self, &'static str> {
        if variables > 128 {
            return Err("variable limit");
        }
        let mut solver = Self {
            clauses: vec![],
            watchers: vec![vec![]; variables * 2],
            assignment: vec![-1; variables],
            trail: vec![],
            head: 0,
            inconsistent: false,
        };
        for raw in input {
            let mut literals = Vec::new();
            let mut tautology = false;
            for &literal in raw {
                if literal == 0 || literal.unsigned_abs() as usize > variables {
                    return Err("invalid literal");
                }
                if literals.contains(&-literal) {
                    tautology = true;
                }
                if !literals.contains(&literal) {
                    literals.push(literal);
                }
            }
            if tautology {
                continue;
            }
            if literals.is_empty() {
                solver.inconsistent = true;
                continue;
            }
            let second = usize::from(literals.len() > 1);
            let id = solver.clauses.len();
            solver.watchers[index(literals[0])].push(id);
            if second != 0 {
                solver.watchers[index(literals[second])].push(id);
            }
            if literals.len() == 1 && !solver.enqueue(literals[0]) {
                solver.inconsistent = true;
            }
            solver.clauses.push(Clause {
                literals,
                watched: [0, second],
            });
        }
        Ok(solver)
    }
    fn value(&self, literal: i32) -> Option<bool> {
        let assignment = self.assignment[literal.unsigned_abs() as usize - 1];
        if assignment < 0 {
            None
        } else {
            Some((assignment == 1) == (literal > 0))
        }
    }
    fn enqueue(&mut self, literal: i32) -> bool {
        if let Some(value) = self.value(literal) {
            return value;
        }
        self.assignment[literal.unsigned_abs() as usize - 1] = i8::from(literal > 0);
        self.trail.push(literal);
        true
    }
    fn propagate(&mut self) -> bool {
        while self.head < self.trail.len() {
            let falsified = -self.trail[self.head];
            self.head += 1;
            let slot = index(falsified);
            let pending = std::mem::take(&mut self.watchers[slot]);
            for (position, &id) in pending.iter().enumerate() {
                let clause = &self.clauses[id];
                let which = if clause.literals[clause.watched[0]] == falsified {
                    0
                } else {
                    1
                };
                debug_assert_eq!(clause.literals[clause.watched[which]], falsified);
                let other_index = clause.watched[1 - which];
                let other = clause.literals[other_index];
                if self.value(other) == Some(true) {
                    self.watchers[slot].push(id);
                    continue;
                }
                let replacement = (0..clause.literals.len()).find(|&candidate| {
                    candidate != other_index
                        && self.value(clause.literals[candidate]) != Some(false)
                });
                if let Some(candidate) = replacement {
                    let literal = clause.literals[candidate];
                    self.clauses[id].watched[which] = candidate;
                    self.watchers[index(literal)].push(id);
                } else {
                    self.watchers[slot].push(id);
                    if !self.enqueue(other) {
                        // Preserve unprocessed watcher entries after a conflict.
                        // Watch locations survive backtracking; dropping entries
                        // here would silently make future branches unsound.
                        self.watchers[slot].extend_from_slice(&pending[position + 1..]);
                        return false;
                    }
                }
            }
        }
        true
    }
    fn undo(&mut self, mark: usize) {
        for literal in self.trail.drain(mark..) {
            self.assignment[literal.unsigned_abs() as usize - 1] = -1;
        }
        self.head = self.head.min(mark);
    }
    fn search(&mut self) -> bool {
        if !self.propagate() {
            return false;
        }
        let Some(variable) = self.assignment.iter().position(|&value| value < 0) else {
            return true;
        };
        let mark = self.trail.len();
        let literal = (variable + 1) as i32;
        for choice in [literal, -literal] {
            self.enqueue(choice);
            if self.search() {
                return true;
            }
            self.undo(mark);
        }
        false
    }
    fn solve(mut self) -> Option<Vec<bool>> {
        if self.inconsistent || !self.search() {
            None
        } else {
            Some(self.assignment.iter().map(|&value| value == 1).collect())
        }
    }
}
fn satisfies(formula: &[Vec<i32>], model: &[bool]) -> bool {
    formula.iter().all(|clause| {
        clause
            .iter()
            .any(|&lit| model[lit.unsigned_abs() as usize - 1] == (lit > 0))
    })
}
fn brute(variables: usize, formula: &[Vec<i32>]) -> bool {
    (0..1usize << variables).any(|bits| {
        let model = (0..variables)
            .map(|i| bits & (1 << i) != 0)
            .collect::<Vec<_>>();
        satisfies(formula, &model)
    })
}
fn main() {
    assert!(Solver::new(1, &[vec![1], vec![-1]])
        .unwrap()
        .solve()
        .is_none());
    assert!(Solver::new(0, &[]).unwrap().solve().is_some());
    assert!(Solver::new(0, &[vec![]]).unwrap().solve().is_none());
    assert!(Solver::new(2, &[vec![0]]).is_err());
    assert!(Solver::new(2, &[vec![i32::MIN]]).is_err());
    assert!(Solver::new(1, &[vec![1, 1, -1]]).unwrap().solve().is_some());
    let mut seed = 61u64;
    for trial in 0..1500 {
        let variables = 1 + trial % 7;
        let mut formula = vec![];
        for _ in 0..trial % 25 {
            seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
            let length = (seed >> 32) as usize % 5;
            let mut clause = vec![];
            for _ in 0..length {
                seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
                let literal = 1 + ((seed >> 16) as usize % variables) as i32;
                clause.push(if seed & 1 == 0 { literal } else { -literal });
            }
            formula.push(clause);
        }
        let model = Solver::new(variables, &formula).unwrap().solve();
        assert_eq!(
            model.is_some(),
            brute(variables, &formula),
            "trial {trial}: {formula:?}"
        );
        if let Some(model) = model {
            assert!(satisfies(&formula, &model));
        }
    }
    // Pigeonhole: three pigeons cannot occupy two holes without sharing.
    let mut pigeon = vec![vec![1, 2], vec![3, 4], vec![5, 6]];
    for a in 0..3 {
        for b in a + 1..3 {
            for hole in 0..2 {
                pigeon.push(vec![-(a * 2 + hole + 1), -(b * 2 + hole + 1)]);
            }
        }
    }
    assert!(Solver::new(6, &pigeon).unwrap().solve().is_none());
    println!("Watched SAT: trail restoration, pigeonhole and 1500 exhaustive-oracle CNFs passed");
}
