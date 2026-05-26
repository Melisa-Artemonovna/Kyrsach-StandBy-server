using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Kourse_project_BD_vav.Models
{
    public class UserActivity
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int activity_id { get; set; }

        public int user_id { get; set; }

        [MaxLength(50)]
        public string activity_type { get; set; } = string.Empty;

        [MaxLength(255)]
        public string? description { get; set; }

        public DateTime created_at { get; set; }
    }
}