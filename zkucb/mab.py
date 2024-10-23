import numpy as np

# multi-armed bandits with k arms, numbered 0, 1, ..., i, ..., k-1
# the reward of each arm a_i is a random variable with a gaussian distribution
# with mean mu_i and variance sigma^2
# mu_i is from a gaussian distribution with mean 0 and variance sigma^2.


class MAB:
    def __init__(self):
        self.arms = 3
        self.sigma = 1
        self.means = np.array([0.9, 1.0, 1.1])

    def pull(self, i):
        return np.random.normal(self.means[i], self.sigma)
    
    def reset(self):
        self.means = np.random.normal(0, self.sigma, self.arms)

    def print_means(self):
        print("Means: ", self.means)