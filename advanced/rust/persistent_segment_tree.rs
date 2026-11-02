//! Immutable lazy range-add / range-sum tree with historical versions.
//! rustc --edition=2021 persistent_segment_tree.rs -o tree && ./tree
//! Half-open ranges [start,end); O(log n) copied nodes per update/query.
//! Values are bounded in the demo; arbitrary inputs can overflow signed i64.
use std::sync::Arc;

#[derive(Debug)]
struct Node {
    sum: i64,
    lazy: i64,
    left: Option<Arc<Node>>,
    right: Option<Arc<Node>>,
}

#[derive(Clone)]
struct Tree {
    root: Arc<Node>,
    length: usize,
}

impl Node {
    fn build(values: &[i64]) -> Arc<Self> {
        if values.len() == 1 {
            return Arc::new(Self {
                sum: values[0],
                lazy: 0,
                left: None,
                right: None,
            });
        }
        let middle = values.len() / 2;
        let left = Self::build(&values[..middle]);
        let right = Self::build(&values[middle..]);
        Arc::new(Self {
            sum: left.sum + right.sum,
            lazy: 0,
            left: Some(left),
            right: Some(right),
        })
    }

    fn add(
        node: &Arc<Self>,
        low: usize,
        high: usize,
        start: usize,
        end: usize,
        delta: i64,
    ) -> Arc<Self> {
        if end <= low || high <= start {
            return node.clone();
        }
        if start <= low && high <= end {
            return Arc::new(Self {
                sum: node.sum + delta * (high - low) as i64,
                lazy: node.lazy + delta,
                left: node.left.clone(),
                right: node.right.clone(),
            });
        }
        let middle = low + (high - low) / 2;
        let left = Self::add(node.left.as_ref().unwrap(), low, middle, start, end, delta);
        let right = Self::add(
            node.right.as_ref().unwrap(),
            middle,
            high,
            start,
            end,
            delta,
        );
        // Leave this node's lazy contribution at this level. Children do not
        // include it, so queries carry ancestor increments instead of mutating.
        Arc::new(Self {
            sum: left.sum + right.sum + node.lazy * (high - low) as i64,
            lazy: node.lazy,
            left: Some(left),
            right: Some(right),
        })
    }

    fn query(&self, low: usize, high: usize, start: usize, end: usize, carry: i64) -> i64 {
        if end <= low || high <= start {
            return 0;
        }
        if start <= low && high <= end {
            return self.sum + carry * (high - low) as i64;
        }
        let middle = low + (high - low) / 2;
        let carry = carry + self.lazy;
        self.left
            .as_ref()
            .unwrap()
            .query(low, middle, start, end, carry)
            + self
                .right
                .as_ref()
                .unwrap()
                .query(middle, high, start, end, carry)
    }
}

impl Tree {
    fn new(values: &[i64]) -> Result<Self, &'static str> {
        if values.is_empty() {
            return Err("empty tree");
        }
        Ok(Self {
            root: Node::build(values),
            length: values.len(),
        })
    }
    fn valid(&self, start: usize, end: usize) -> Result<(), &'static str> {
        if start > end || end > self.length {
            Err("invalid range")
        } else {
            Ok(())
        }
    }
    fn add(&self, start: usize, end: usize, delta: i64) -> Result<Self, &'static str> {
        self.valid(start, end)?;
        if start == end {
            return Ok(self.clone());
        }
        Ok(Self {
            root: Node::add(&self.root, 0, self.length, start, end, delta),
            length: self.length,
        })
    }
    fn sum(&self, start: usize, end: usize) -> Result<i64, &'static str> {
        self.valid(start, end)?;
        Ok(self.root.query(0, self.length, start, end, 0))
    }
}

fn check(tree: &Tree, reference: &[i64]) {
    for start in 0..=reference.len() {
        for end in start..=reference.len() {
            assert_eq!(
                tree.sum(start, end).unwrap(),
                reference[start..end].iter().sum::<i64>(),
                "range {start}..{end}"
            );
        }
    }
}

fn main() {
    let original = Tree::new(&[1, 2, 3, 4, 5]).unwrap();
    let changed = original.add(0, 5, 10).unwrap().add(1, 4, -3).unwrap();
    check(&original, &[1, 2, 3, 4, 5]);
    check(&changed, &[11, 9, 10, 11, 15]);
    assert!(original.add(4, 3, 1).is_err());
    assert!(original.sum(0, 6).is_err());
    assert!(Tree::new(&[]).is_err());
    let untouched = original.add(2, 2, 999).unwrap();
    assert!(Arc::ptr_eq(&original.root, &untouched.root));
    let only_left = original.add(0, 1, 1).unwrap();
    assert!(Arc::ptr_eq(
        original.root.right.as_ref().unwrap(),
        only_left.root.right.as_ref().unwrap()
    ));
    // Branch from old versions, not only the newest one. Differential checks
    // catch lazy propagation bugs that point queries alone often miss.
    let mut versions = vec![(Tree::new(&[0; 17]).unwrap(), vec![0i64; 17])];
    let mut seed = 37u64;
    for step in 0..150 {
        seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1);
        let parent = seed as usize % versions.len();
        let start = (seed >> 16) as usize % 18;
        let end = start + (seed >> 32) as usize % (18 - start);
        let delta = step % 11 - 5;
        let (tree, reference) = &versions[parent];
        let tree = tree.add(start, end, delta).unwrap();
        let mut reference = reference.clone();
        for value in &mut reference[start..end] {
            *value += delta;
        }
        check(&tree, &reference);
        versions.push((tree, reference));
    }
    for (tree, reference) in versions {
        check(&tree, &reference);
    }
    println!("Persistent lazy tree: branched versions, every range and structural sharing passed");
}
