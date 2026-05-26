using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace Kourse_project_BD_vav.Models
{
    public class Client
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int client_id { get; set; }

        [Required]
        [MaxLength(100)]
        public string full_name { get; set; } = string.Empty;

        [MaxLength(20)]
        public string phone_number { get; set; } = string.Empty;

        [MaxLength(100)]
        public string email { get; set; } = string.Empty;

        [MaxLength(20)]
        public string passport_number { get; set; } = string.Empty;

        public DateTime registration_date { get; set; }

        // Внешний ключ для User
        public int? user_id { get; set; }
        public virtual ICollection<PropertyReservation> Reservations { get; set; } = new List<PropertyReservation>();
    }
}