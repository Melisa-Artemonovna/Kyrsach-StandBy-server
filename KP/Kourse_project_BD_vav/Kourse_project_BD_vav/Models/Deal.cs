using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Kourse_project_BD_vav.Models
{
    public class Deal
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int deal_id { get; set; }

        [Required]
        public int property_id { get; set; }

        [Required]
        public int client_id { get; set; }

        public int? realtor_id { get; set; }

        [MaxLength(50)]
        public string? deal_type { get; set; } // Например: Аренда, Продажа

        [MaxLength(50)]
        public string? deal_status { get; set; } // Статус сделки

        public DateTime deal_date { get; set; }

        [Range(0, double.MaxValue)]
        public decimal deal_price { get; set; }

        // Навигационные свойства
        [ForeignKey("property_id")]
        public virtual Property? property { get; set; }

        [ForeignKey("client_id")]
        public virtual Client? client { get; set; }

        [ForeignKey("realtor_id")]
        public virtual Realtor? realtor { get; set; }
    }
}
