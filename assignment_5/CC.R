#'@title Experience weighted attraction model
#'@description
#'
#'@param gb_1 initial belief about what other will contribute
#'@param omega_1 init weighting of beliefs about others contributions
#'@param lambda  decay rate in weighting of beliefs
#'@param gamma  weighting of beliefs about what others will contribute
#'@param p_0 intercept of linear model relating prefered contrib. to possible contrib. vals
#'@param p_beta slope of linear model relating prefered contrib. to possible contrib. vals
#'
#'@author
#'K. Enevoldsen
#'
#'@return 
#' The actions of the agent
#'
#'@references
#'
#'@export

CC <- function(n_agents, n_trials, vals, parameters) {
  # Free parameters
  gb_1 <- parameters$gb_1 
  omega_1 <- parameters$omega_1 # init weighting of beliefs about others contributions
  lambda <- parameters$lambda # decay rate in weighting of beliefs
  gamma <- parameters$gamma # weighting of beliefs about what others will contribute
  p_0 <- parameters$p_0 # intercept of linear model relating preferred contributions to possible contribution vals
  p_beta <- parameters$p_beta # # slope of linear model relating ^^^
  
  # Sim arrays
  ga <- array(0, c(n_trials)) # observed others' contribution (mean of all others)
  gb <- array(0, c(n_agents, n_trials)) # beliefs about others' contribution (mean of all others)
  p <- array(0, c(n_agents, n_trials)) # preferred contrib on each trial (independent of belief)
  omega <- array(0, c(n_agents, n_trials)) # weighting of beliefs about others' contrib rel. to prefs
  c <- array(0, c(n_agents, n_trials)) # actual contributions
  
  # Agents' prefererences - assumed to be a linear function of possible values
  p_vals <- p_0 + (matrix(p_beta) %*% vals)
  
  p_beta <- if_else(round(p_vals[, ncol(p_vals)], 0) > max(vals), (20-p_0)/20, p_beta) 
  # recalculate p_vals
  p_vals <- p_0 + (matrix(p_beta) %*% vals)
  parameters$p_beta <- p_beta
  # set omega as starting weighting
  omega[,1] <- omega_1
  # set starting beliefs about what others will contribute
  gb[,1] <- gb_1
  # set average first trial contribution to average belief, assume full cooperation at outset
  c[,1] <- gb_1
  ga[1] <- mean(gb_1)
  
  for (t in 2:n_trials) {
    # cat("\ntrial:", t)
    for (n in 1:n_agents) {
      # cat("\n\tagent:", n)
      # update belief about what others contribute as a weighted average of prior beliefs and observed contributions
      gb[n, t] <- (gamma[n] * (gb[n, t-1])) + ((1 - gamma[n]) * (ga[t-1]))
      # determine what people predict/prefer to contribute, given the group contriution
      p[n, t] <- p_vals[n, round(gb[n, t])]
      # update relative weighting of beliefs about others contribution using decay function
      omega[n, t] <- omega[n, t-1] * (1 - lambda[n])
      # subjects contribute a weighted average of predicted/preferred contribution and belief
      c[n, t] <- ceiling((omega[n, t]) * gb[n, t] + ((1 - omega[n, t]) * p[n, t]))
      
    }
    # recode avg contrib as observed belief about how much each agent contributed ga
    ga[t] <- sum(c[, t]) / n_agents
    
  }
  
  results <- list(c = c,
                  omega = omega,
                  parameters = parameters,
                  ga = ga, 
                  vals = vals,
                  start_params=parameters)
  return(results)
}


