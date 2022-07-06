#' @rdname learn.network.custom
#' @aliases learn.network.custom,BNDataset
setMethod("learn.network.custom",
          c("BNDataset"),
          function(x, algo='K2', scoring.func='default', 
                   order=c(1,2,3), max.parents=2, f=score,
                   initial.network=NULL){
              dataset <- x
              bn <- BN(dataset)
              
              # setup
              num.nodes(bn)  <- num.variables(dataset)
              node.sizes(bn) <- node.sizes(dataset)
              variables(bn)  <- variables(dataset)
              validObject(bn)

              node.sizes <- node.sizes(bn)
              num.nodes  <- num.nodes(bn)
              
              # get initial.network
              if (!is.null(initial.network)){
                  if (inherits(initial.network, "BN"))
                      init.net <- initial.network
                  else if (inherits(initial.network, "matrix")){
                    init.net      <- BN(dataset)
                    dag(init.net) <- initial.network
                    init.net      <- learn.params(init.net, dataset)
                  }
                  else if (inherits(initial.network, "character") &&
                           tolower(initial.network) == "random.chain")
                      init.net <- sample.chain(dataset)
                  else # string != "random.chain"
                      init.net <- NULL
                  if (!is.null(init.net))
                      validObject(init.net)
              }
              else
                  init.net <- NULL
              
              
              
              # select columns in the right order
              nodes <- as.data.frame(raw.data(data.BND))
              
              # number of nodes
              n <- length(nodes)

              # empty vector to store the parents of each node
              parents <- rep(NULL, 0)
    
              g.nodes <- names(nodes)
    
              dag.matrix <- matrix(0, nrow=n, ncol=n)

              for( i in 1:n ){
                  # empty vector to store the parents of each node
                  parents <- character()
                  p.old   <- f(nodes[i], nodes[parents])
                  ok.to.proceed <- TRUE
                  pred_xi <- g.nodes[1:i-1]

                  while(ok.to.proceed & length(parents)<max.parents){
                      # create a list with the possible parent nodes to inspect
                      unions      <- lapply(setdiff(pred_xi, parents), union, parents)

                      new.parents <- unlist(unions[which.max(sapply(unions, function(x) f(nodes[i], nodes[x])))])
                      p.new       <- f(nodes[i], nodes[new.parents])

                      if(p.new > p.old){
                          p.old   <- p.new
                          parents <- new.parents
                      }
                      else{
                          ok.to.proceed <- FALSE
                      }
                  }
                  for (p in parents){
                      row <- grep(p, g.nodes)
                      dag.matrix[row, i] <- 1
                  }
              }
              dag(bn) <- dag.matrix
              bn <- learn.params(bn, dataset)
              return(bn)
          })