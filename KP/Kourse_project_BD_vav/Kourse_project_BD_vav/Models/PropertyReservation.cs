using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Kourse_project_BD_vav.Models
{
    public class PropertyReservation
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int reservation_id { get; set; }

        public int property_id { get; set; }
        public int client_id { get; set; }
        public int realtor_id { get; set; }
        public DateTime reservation_date { get; set; }
        public DateTime expiry_date { get; set; }

        [MaxLength(20)]
        public string status { get; set; } = "Active";

        // Навигационные свойства (настройка связей через Fluent API в DbContext)
        [ForeignKey("property_id")]
        public virtual Property Property { get; set; } = null!;
        
        [ForeignKey("client_id")]
        public virtual Client Client { get; set; } = null!;
        
        [ForeignKey("realtor_id")]
        public virtual Realtor Realtor { get; set; } = null!;
    }
}