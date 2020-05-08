using System;
using System.Collections.Generic;
using System.Text;

namespace PossumLabs.TestResults.Contract
{
    public class ResultsFileRequest
    {
        /// <summary>
        /// Url for the Repo that the Possum Lab is set up for
        /// </summary>
        public string RepoUrl { get; set; }
        /// <summary>
        /// The process that created these results, this can be a brach name (for instance "4.2"), 
        /// run type (for instance "Nightly", "Regression"), or Environment (for instance "Test", "Staging") 
        /// or some composit ("Nightly Staging 4.2").  
        /// </summary>
        public string ProcessName { get; set; }
        /// <summary>
        /// probably the date, or some composite (for instance "1/1/2000" or "1/1/2000 noon")
        /// </summary>
        public string RunName { get; set; }
        /// <summary>
        /// timestamp to associate the run to, optional
        /// </summary>
        public DateTime? RunDate { get; set; }
    }
}
