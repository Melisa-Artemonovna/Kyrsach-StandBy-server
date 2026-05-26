using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Kourse_project_BD_vav.Models
{
    [Table("Properties")]
    public class Property
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int property_id { get; set; }

        [Required]
        [MaxLength(255)]
        public string address { get; set; } = string.Empty;

        [MaxLength(50)]
        public string? property_type { get; set; }

        [Required]
        [Range(0.1, double.MaxValue)]
        public decimal area { get; set; }

        [Required]
        [Range(1, double.MaxValue)]
        public decimal price { get; set; }

        public string? description { get; set; }

        public int? realtor_id { get; set; }

        public bool is_available { get; set; } = true;

        public string? main_image_url { get; set; }

        public string? image_urls { get; set; }

        [Range(0, 50)]
        public int? rooms { get; set; }

        [Range(0, 200)]
        public int? floor { get; set; }

        [Range(1, 200)]
        public int? total_floors { get; set; }
    }
}