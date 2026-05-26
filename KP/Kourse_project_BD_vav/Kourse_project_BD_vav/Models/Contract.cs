using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Kourse_project_BD_vav.Models
{
    public class Contract
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int contract_id { get; set; }

        [Required]
        public int deal_id { get; set; }

        public DateTime contract_date { get; set; }

        [MaxLength(255)]
        public string contract_file { get; set; } = string.Empty;

        public string notes { get; set; } = string.Empty;
    }
}