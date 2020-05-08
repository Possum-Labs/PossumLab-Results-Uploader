using System;

namespace PossumLabs.TestResults.Contract
{
    public class ResultsFileTicket
    {
        /// <summary>
        /// Ticket to refer to this request
        /// </summary>
        public string Ticket { get; set; }
        /// <summary>
        /// Location to place the file; you'll need to update the placeholder
        /// </summary>
        public Uri FileLocation { get; set; }
        /// <summary>
        /// Needed to perform the update, this is an azure delegation key
        /// </summary>
        public string Token { get; set; }
    }
}
